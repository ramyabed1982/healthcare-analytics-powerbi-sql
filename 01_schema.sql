PRAGMA foreign_keys = ON;

CREATE TABLE departments (
    department_id INTEGER PRIMARY KEY,
    department_name TEXT NOT NULL UNIQUE,
    service_line TEXT NOT NULL,
    capacity_beds INTEGER NOT NULL CHECK (capacity_beds >= 0),
    daily_room_rate REAL NOT NULL CHECK (daily_room_rate >= 0)
);

CREATE TABLE patients (
    patient_id INTEGER PRIMARY KEY,
    date_of_birth TEXT NOT NULL,
    gender TEXT NOT NULL,
    state TEXT NOT NULL,
    payer_type TEXT NOT NULL
);

CREATE TABLE diagnoses (
    diagnosis_code TEXT PRIMARY KEY,
    diagnosis_name TEXT NOT NULL,
    diagnosis_category TEXT NOT NULL,
    severity_score INTEGER NOT NULL CHECK (severity_score BETWEEN 1 AND 5)
);

CREATE TABLE procedures (
    procedure_code TEXT PRIMARY KEY,
    procedure_name TEXT NOT NULL,
    procedure_category TEXT NOT NULL,
    default_department_id INTEGER,
    base_cost REAL NOT NULL CHECK (base_cost >= 0),
    FOREIGN KEY (default_department_id) REFERENCES departments(department_id)
);

CREATE TABLE visits (
    visit_id INTEGER PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    department_id INTEGER NOT NULL,
    admit_datetime TEXT NOT NULL,
    discharge_datetime TEXT NOT NULL,
    visit_type TEXT NOT NULL CHECK (visit_type IN ('Inpatient','Emergency','Outpatient')),
    discharge_disposition TEXT NOT NULL,
    source_channel TEXT NOT NULL,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CHECK (discharge_datetime > admit_datetime)
);

CREATE TABLE visit_diagnoses (
    visit_id INTEGER NOT NULL,
    diagnosis_code TEXT NOT NULL,
    is_primary INTEGER NOT NULL CHECK (is_primary IN (0,1)),
    PRIMARY KEY (visit_id, diagnosis_code),
    FOREIGN KEY (visit_id) REFERENCES visits(visit_id),
    FOREIGN KEY (diagnosis_code) REFERENCES diagnoses(diagnosis_code)
);

CREATE TABLE visit_procedures (
    visit_procedure_id INTEGER PRIMARY KEY,
    visit_id INTEGER NOT NULL,
    procedure_code TEXT NOT NULL,
    procedure_datetime TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    actual_cost REAL NOT NULL CHECK (actual_cost >= 0),
    FOREIGN KEY (visit_id) REFERENCES visits(visit_id),
    FOREIGN KEY (procedure_code) REFERENCES procedures(procedure_code)
);

CREATE TABLE costs (
    cost_id INTEGER PRIMARY KEY,
    visit_id INTEGER NOT NULL UNIQUE,
    room_cost REAL NOT NULL,
    procedure_cost REAL NOT NULL,
    medication_cost REAL NOT NULL,
    lab_cost REAL NOT NULL,
    imaging_cost REAL NOT NULL,
    other_cost REAL NOT NULL,
    total_cost REAL NOT NULL,
    FOREIGN KEY (visit_id) REFERENCES visits(visit_id)
);

CREATE TABLE daily_utilization (
    utilization_date TEXT NOT NULL,
    department_id INTEGER NOT NULL,
    occupied_beds INTEGER NOT NULL CHECK (occupied_beds >= 0),
    capacity_beds INTEGER NOT NULL CHECK (capacity_beds > 0),
    utilization_rate REAL NOT NULL CHECK (utilization_rate >= 0),
    PRIMARY KEY (utilization_date, department_id),
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

CREATE INDEX idx_visits_patient_admit ON visits(patient_id, admit_datetime);
CREATE INDEX idx_visits_department_admit ON visits(department_id, admit_datetime);
CREATE INDEX idx_visits_type ON visits(visit_type);
CREATE INDEX idx_visit_dx_code ON visit_diagnoses(diagnosis_code, visit_id);
CREATE INDEX idx_visit_proc_code ON visit_procedures(procedure_code, visit_id);
