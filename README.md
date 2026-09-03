# Healthcare Analytics: SQL + Power BI

Healthcare analytics portfolio project analyzing patient encounters,
30-day readmissions, length of stay, healthcare costs, patient volume,
procedures, diagnoses, and hospital bed utilization.

## Project Overview

This project demonstrates an end-to-end healthcare analytics workflow
using:

- SQL
- SQLite
- Power BI
- DAX
- Power Query
- Data Modeling
- Healthcare KPI Analysis

The dataset contains approximately 37,000 synthetic patient visits
across multiple hospital departments.

## Key KPIs

- Total Visits: 37,154
- Unique Patients: 7,903
- Inpatient Visits: 11,171
- Average Inpatient LOS: 4.29 days
- 30-Day Readmission Rate: 14.63%
- Total Healthcare Cost: approximately $446.8M
- Bed Utilization: approximately 63.9%

## Business Questions

The project addresses questions such as:

- Which departments have the highest readmission rates?
- How is patient volume changing over time?
- Which departments have the highest average LOS?
- What diagnoses are driving healthcare costs?
- How efficiently is hospital capacity being utilized?
- Which patient groups are frequent utilizers?
- Which departments have high costs and poor clinical outcomes?

## SQL Techniques

Advanced SQL techniques used include:

- CTEs
- Window functions
- LAG and LEAD
- NTILE
- Ranking
- Rolling averages
- Cohort analysis
- Conditional aggregation
- Readmission logic

## Power BI

The Power BI model uses a star-schema design containing:

- FactVisits
- FactDailyUtilization
- DimPatients
- DimDepartments
- DimDate
- DimDiagnoses
- DimProcedures
- BridgeVisitDiagnoses
- BridgeVisitProcedures

## Data Disclaimer

All patient and healthcare data in this project is synthetic and was
created solely for educational and portfolio purposes. No real patient
data or protected health information (PHI) is included.
