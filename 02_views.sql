DROP VIEW IF EXISTS vw_visit_metrics;
CREATE VIEW vw_visit_metrics AS
WITH inpatient_sequence AS (
    SELECT
        v.visit_id,
        v.patient_id,
        v.discharge_datetime,
        LEAD(v.admit_datetime) OVER (
            PARTITION BY v.patient_id
            ORDER BY v.admit_datetime, v.visit_id
        ) AS next_inpatient_admit
    FROM visits v
    WHERE v.visit_type = 'Inpatient'
),
primary_dx AS (
    SELECT vd.visit_id, vd.diagnosis_code, d.diagnosis_name, d.diagnosis_category, d.severity_score
    FROM visit_diagnoses vd
    JOIN diagnoses d ON d.diagnosis_code = vd.diagnosis_code
    WHERE vd.is_primary = 1
)
SELECT
    v.visit_id,
    v.patient_id,
    v.department_id,
    d.department_name,
    d.service_line,
    date(v.admit_datetime) AS admit_date,
    date(v.discharge_datetime) AS discharge_date,
    v.admit_datetime,
    v.discharge_datetime,
    v.visit_type,
    v.discharge_disposition,
    v.source_channel,
    p.gender,
    p.payer_type,
    CAST((julianday(v.admit_datetime) - julianday(p.date_of_birth)) / 365.25 AS INTEGER) AS age_at_visit,
    ROUND((julianday(v.discharge_datetime) - julianday(v.admit_datetime)), 2) AS los_days,
    pd.diagnosis_code AS primary_diagnosis_code,
    pd.diagnosis_name AS primary_diagnosis,
    pd.diagnosis_category,
    pd.severity_score,
    c.room_cost,
    c.procedure_cost,
    c.medication_cost,
    c.lab_cost,
    c.imaging_cost,
    c.other_cost,
    c.total_cost,
    CASE
        WHEN v.visit_type = 'Inpatient' AND v.discharge_disposition NOT IN ('Expired','Transfer') THEN 1
        ELSE 0
    END AS eligible_readmission_index,
    CASE
        WHEN v.visit_type = 'Inpatient'
         AND v.discharge_disposition NOT IN ('Expired','Transfer')
         AND s.next_inpatient_admit IS NOT NULL
         AND julianday(s.next_inpatient_admit) - julianday(v.discharge_datetime) BETWEEN 0 AND 30
        THEN 1 ELSE 0
    END AS readmitted_30d,
    s.next_inpatient_admit
FROM visits v
JOIN patients p ON p.patient_id = v.patient_id
JOIN departments d ON d.department_id = v.department_id
JOIN costs c ON c.visit_id = v.visit_id
LEFT JOIN primary_dx pd ON pd.visit_id = v.visit_id
LEFT JOIN inpatient_sequence s ON s.visit_id = v.visit_id;

DROP VIEW IF EXISTS vw_monthly_department_metrics;
CREATE VIEW vw_monthly_department_metrics AS
SELECT
    substr(admit_date,1,7) AS year_month,
    department_id,
    department_name,
    COUNT(*) AS total_visits,
    SUM(CASE WHEN visit_type='Inpatient' THEN 1 ELSE 0 END) AS inpatient_visits,
    ROUND(AVG(CASE WHEN visit_type='Inpatient' THEN los_days END),2) AS avg_inpatient_los,
    SUM(readmitted_30d) AS readmissions_30d,
    SUM(eligible_readmission_index) AS eligible_index_admissions,
    ROUND(100.0 * SUM(readmitted_30d) / NULLIF(SUM(eligible_readmission_index),0),2) AS readmission_rate_pct,
    ROUND(SUM(total_cost),2) AS total_cost,
    ROUND(AVG(total_cost),2) AS avg_cost_per_visit
FROM vw_visit_metrics
GROUP BY substr(admit_date,1,7), department_id, department_name;
