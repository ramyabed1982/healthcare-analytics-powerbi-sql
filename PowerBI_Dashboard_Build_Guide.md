# Power BI Dashboard Build Guide — Healthcare Utilization & Readmissions

## 1. Load the data
Use **Get Data → Text/CSV** and import the files from the `data` folder. Rename tables:

- `fact_visits.csv` → **FactVisits**
- `dim_patients.csv` → **DimPatients**
- `dim_departments.csv` → **DimDepartments**
- `dim_date.csv` → **DimDate**
- `dim_diagnoses.csv` → **DimDiagnoses**
- `dim_procedures.csv` → **DimProcedures**
- `bridge_visit_diagnoses.csv` → **BridgeVisitDiagnoses**
- `bridge_visit_procedures.csv` → **BridgeVisitProcedures**
- `fact_daily_utilization.csv` → **FactDailyUtilization**

Set `DimDate[date]`, `FactVisits[admit_date]`, and `FactDailyUtilization[date]` to **Date** data type.
Set cost columns to **Decimal/Currency** and the two rate flags to **Whole Number**.

## 2. Model relationships
Create these one-to-many, single-direction relationships:

1. `DimPatients[patient_id]` 1 → * `FactVisits[patient_id]`
2. `DimDepartments[department_id]` 1 → * `FactVisits[department_id]`
3. `DimDate[date]` 1 → * `FactVisits[admit_date]`
4. `DimDepartments[department_id]` 1 → * `FactDailyUtilization[department_id]`
5. `DimDate[date]` 1 → * `FactDailyUtilization[date]`
6. `FactVisits[visit_id]` 1 → * `BridgeVisitDiagnoses[visit_id]`
7. `DimDiagnoses[diagnosis_code]` 1 → * `BridgeVisitDiagnoses[diagnosis_code]`
8. `FactVisits[visit_id]` 1 → * `BridgeVisitProcedures[visit_id]`
9. `DimProcedures[procedure_code]` 1 → * `BridgeVisitProcedures[procedure_code]`

Mark **DimDate** as the date table using `DimDate[date]`.

## 3. Create measures
Paste every measure in `DAX_Measures.txt` into Power BI. Format:

- Readmission and utilization measures → Percentage, 1 decimal place
- Cost measures → Currency, 0 or 2 decimals
- LOS → Decimal, 1 decimal place
- Visit/patient counts → Whole number

## 4. Page 1 — Executive Overview
Use a 16:9 page. Add slicers across the top for **Date**, **Department**, **Visit Type**, and **Payer Type**.

**KPI cards**
- 30-Day Readmission Rate
- Average Length of Stay
- Total Visits
- Average Cost per Visit
- Bed Utilization Rate

**Charts**
- Line and clustered column chart: Axis = `DimDate[year_month]`; columns = Total Visits; line = Average Length of Stay
- Bar chart: Department → 30-Day Readmission Rate
- Line chart: `DimDate[year_month]` → Total Cost
- Donut or 100% stacked bar: Visit Type → Total Visits

## 5. Page 2 — Utilization & Capacity
**Cards**: Inpatient Visits, Inpatient Days, Bed Utilization Rate, Cost per Inpatient Day.

**Charts**
- Line chart: Date/month → Bed Utilization Rate, legend = Department
- Matrix: Rows = Department; Columns = `DimDate[year_month]`; Values = Bed Utilization Rate; apply conditional formatting
- Bar chart: Department → Inpatient Visits
- Combo chart: Department → Inpatient Days and Total Cost
- Bar chart: Procedure Name → Procedure Units per 100 Visits

## 6. Page 3 — Clinical Outcomes & Cost
**Charts**
- Bar chart: Primary Diagnosis → Total Visits (Top 10)
- Bar chart: Primary Diagnosis → Average Cost per Visit (Top 10 by cost)
- Bar chart: Primary Diagnosis → 30-Day Readmission Rate
- Scatter chart: X = Average Length of Stay; Y = Average Cost per Visit; Size = Total Visits; Details = Department
- Table: Diagnosis, Visits, Avg LOS, Readmission Rate, Avg Cost

## 7. Page 4 — Readmission & Patient Flow
**Charts**
- Line chart: Month → 30-Day Readmission Rate
- Bar chart: Department → 30-Day Readmission Rate
- Bar chart: Payer Type → 30-Day Readmission Rate
- Stacked bar: Discharge Disposition → Inpatient Visits
- Table: Department, Eligible Index Admissions, 30-Day Readmissions, Readmission Rate, Avg LOS, Avg Cost

## 8. KPI definitions
- **30-Day Readmission Rate** = Readmitted inpatient index admissions ÷ eligible inpatient index admissions.
- **Average Length of Stay** = average elapsed days between admit and discharge for inpatient visits.
- **Patient Volume** can be shown as either Total Visits or Unique Patients; include both to avoid ambiguity.
- **Bed Utilization Rate** = summed occupied bed census ÷ summed staffed bed capacity across selected days.
- **Procedure Utilization** = procedure units per 100 visits.
- **Average Cost per Visit** = total direct synthetic costs ÷ visits.

## 9. Recommended interactions
- Date and department slicers should filter every page.
- Enable drill-through from Department to Clinical Outcomes.
- Add tooltip pages for Department and Diagnosis with Visits, Readmission Rate, LOS, Cost, and Utilization.
- Use a report-page tooltip on monthly trends to show MoM % and rolling 3-month measures.

## 10. Portfolio talking points
- Designed a normalized healthcare database with patient, encounter, diagnosis, procedure, and cost entities.
- Used SQL window functions, CTEs, ranking, rolling calculations, cohort logic, and cost/utilization analysis.
- Defined and implemented a 30-day readmission metric consistently across SQL and Power BI.
- Built a star-schema Power BI model with a date dimension, clinical bridge tables, DAX KPIs, and capacity-utilization fact data.
- Created executive, utilization, clinical-cost, and readmission views for operational decision support.
