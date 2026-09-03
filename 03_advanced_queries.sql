-- Healthcare Analytics: Advanced SQL Queries (SQLite syntax)
-- KPI definition used throughout:
-- 30-day readmission = a subsequent inpatient admission within 30 days of an
-- eligible inpatient discharge (excluding Expired and Transfer dispositions).

-- 1) Overall 30-day readmission rate
SELECT
    SUM(readmitted_30d) AS readmissions_30d,
    SUM(eligible_readmission_index) AS eligible_index_admissions,
    ROUND(100.0 * SUM(readmitted_30d) / NULLIF(SUM(eligible_readmission_index),0), 2) AS readmission_rate_pct
FROM vw_visit_metrics;

-- 2) Readmission rate by department, with ranking
WITH dept AS (
    SELECT department_name,
           SUM(readmitted_30d) AS readmissions,
           SUM(eligible_readmission_index) AS eligible,
           100.0 * SUM(readmitted_30d) / NULLIF(SUM(eligible_readmission_index),0) AS rate
    FROM vw_visit_metrics
    GROUP BY department_name
)
SELECT department_name, readmissions, eligible, ROUND(rate,2) AS readmission_rate_pct,
       DENSE_RANK() OVER (ORDER BY rate DESC) AS readmission_rate_rank
FROM dept
WHERE eligible >= 30
ORDER BY readmission_rate_rank;

-- 3) Monthly patient volume with month-over-month change
WITH monthly AS (
    SELECT substr(admit_date,1,7) AS year_month,
           COUNT(*) AS visits,
           COUNT(DISTINCT patient_id) AS unique_patients
    FROM vw_visit_metrics
    GROUP BY substr(admit_date,1,7)
), lagged AS (
    SELECT *, LAG(visits) OVER (ORDER BY year_month) AS prior_month_visits
    FROM monthly
)
SELECT year_month, visits, unique_patients, prior_month_visits,
       ROUND(100.0*(visits-prior_month_visits)/NULLIF(prior_month_visits,0),2) AS visit_mom_pct
FROM lagged
ORDER BY year_month;

-- 4) Average inpatient LOS by department + comparison to hospital benchmark
WITH dept AS (
    SELECT department_name, AVG(los_days) AS avg_los, COUNT(*) AS inpatient_visits
    FROM vw_visit_metrics
    WHERE visit_type='Inpatient'
    GROUP BY department_name
), benchmark AS (
    SELECT AVG(los_days) AS hospital_avg_los
    FROM vw_visit_metrics
    WHERE visit_type='Inpatient'
)
SELECT d.department_name, d.inpatient_visits,
       ROUND(d.avg_los,2) AS avg_los,
       ROUND(b.hospital_avg_los,2) AS hospital_avg_los,
       ROUND(d.avg_los-b.hospital_avg_los,2) AS variance_days
FROM dept d CROSS JOIN benchmark b
ORDER BY variance_days DESC;

-- 5) Rolling 3-month utilization and visit trend by department
WITH monthly AS (
    SELECT substr(admit_date,1,7) AS year_month, department_name,
           COUNT(*) AS visits,
           SUM(total_cost) AS total_cost
    FROM vw_visit_metrics
    GROUP BY substr(admit_date,1,7), department_name
)
SELECT year_month, department_name, visits, ROUND(total_cost,2) AS total_cost,
       ROUND(AVG(visits) OVER (PARTITION BY department_name ORDER BY year_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),1) AS rolling_3m_avg_visits,
       ROUND(SUM(total_cost) OVER (PARTITION BY department_name ORDER BY year_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS rolling_3m_cost
FROM monthly
ORDER BY department_name, year_month;

-- 6) Cost per inpatient day and cost intensity by department
SELECT department_name,
       COUNT(*) AS inpatient_visits,
       ROUND(SUM(total_cost),2) AS total_cost,
       ROUND(SUM(los_days),2) AS inpatient_days,
       ROUND(SUM(total_cost)/NULLIF(SUM(los_days),0),2) AS cost_per_inpatient_day,
       ROUND(AVG(total_cost),2) AS avg_cost_per_visit
FROM vw_visit_metrics
WHERE visit_type='Inpatient'
GROUP BY department_name
ORDER BY cost_per_inpatient_day DESC;

-- 7) Diagnosis burden: volume, LOS, cost, and readmission
SELECT primary_diagnosis_code, primary_diagnosis, diagnosis_category,
       COUNT(*) AS visits,
       ROUND(AVG(CASE WHEN visit_type='Inpatient' THEN los_days END),2) AS avg_inpatient_los,
       ROUND(AVG(total_cost),2) AS avg_cost,
       SUM(readmitted_30d) AS readmissions,
       SUM(eligible_readmission_index) AS eligible_indices,
       ROUND(100.0*SUM(readmitted_30d)/NULLIF(SUM(eligible_readmission_index),0),2) AS readmission_rate_pct
FROM vw_visit_metrics
GROUP BY primary_diagnosis_code, primary_diagnosis, diagnosis_category
HAVING COUNT(*) >= 50
ORDER BY avg_cost DESC;

-- 8) Procedure utilization and spend per 100 visits
WITH total_visits AS (SELECT COUNT(*) AS n FROM visits),
proc AS (
    SELECT p.procedure_code, p.procedure_name, p.procedure_category,
           COUNT(DISTINCT vp.visit_id) AS visits_with_procedure,
           SUM(vp.quantity) AS procedure_units,
           SUM(vp.actual_cost) AS procedure_spend
    FROM visit_procedures vp
    JOIN procedures p ON p.procedure_code=vp.procedure_code
    GROUP BY p.procedure_code,p.procedure_name,p.procedure_category
)
SELECT procedure_code, procedure_name, procedure_category,
       visits_with_procedure, procedure_units,
       ROUND(procedure_spend,2) AS procedure_spend,
       ROUND(100.0*visits_with_procedure/(SELECT n FROM total_visits),2) AS visits_with_procedure_per_100_visits
FROM proc
ORDER BY procedure_spend DESC;

-- 9) Frequent utilizers: patients with high visit counts and high cost
WITH patient_rollup AS (
    SELECT patient_id, COUNT(*) AS visits, SUM(total_cost) AS total_cost,
           SUM(CASE WHEN visit_type='Emergency' THEN 1 ELSE 0 END) AS ed_visits,
           SUM(CASE WHEN visit_type='Inpatient' THEN 1 ELSE 0 END) AS inpatient_visits
    FROM vw_visit_metrics
    GROUP BY patient_id
), scored AS (
    SELECT *,
           NTILE(100) OVER (ORDER BY visits) AS visit_percentile,
           NTILE(100) OVER (ORDER BY total_cost) AS cost_percentile
    FROM patient_rollup
)
SELECT patient_id, visits, ed_visits, inpatient_visits, ROUND(total_cost,2) AS total_cost,
       visit_percentile, cost_percentile
FROM scored
WHERE visit_percentile >= 95 OR cost_percentile >= 95
ORDER BY total_cost DESC, visits DESC;

-- 10) Payer mix and cost performance
SELECT payer_type,
       COUNT(*) AS visits,
       COUNT(DISTINCT patient_id) AS unique_patients,
       ROUND(AVG(total_cost),2) AS avg_cost_per_visit,
       ROUND(SUM(total_cost),2) AS total_cost,
       ROUND(100.0*SUM(readmitted_30d)/NULLIF(SUM(eligible_readmission_index),0),2) AS readmission_rate_pct
FROM vw_visit_metrics
GROUP BY payer_type
ORDER BY total_cost DESC;

-- 11) Monthly bed utilization from midnight census (capacity-weighted)
SELECT substr(u.utilization_date,1,7) AS year_month, d.department_name,
       ROUND(100.0*SUM(u.occupied_beds)/NULLIF(SUM(u.capacity_beds),0),2) AS utilization_pct
FROM daily_utilization u
JOIN departments d ON d.department_id=u.department_id
GROUP BY substr(u.utilization_date,1,7), d.department_name
ORDER BY year_month, d.department_name;

-- 12) Department performance scorecard with quartiles
WITH scorecard AS (
    SELECT department_name,
           COUNT(*) AS visits,
           AVG(CASE WHEN visit_type='Inpatient' THEN los_days END) AS avg_los,
           AVG(total_cost) AS avg_cost,
           100.0*SUM(readmitted_30d)/NULLIF(SUM(eligible_readmission_index),0) AS readmission_rate
    FROM vw_visit_metrics
    GROUP BY department_name
)
SELECT *,
       NTILE(4) OVER (ORDER BY readmission_rate) AS readmission_quartile_low_is_good,
       NTILE(4) OVER (ORDER BY avg_cost) AS cost_quartile_low_is_good,
       NTILE(4) OVER (ORDER BY avg_los) AS los_quartile_low_is_good
FROM scorecard
ORDER BY readmission_rate DESC;
