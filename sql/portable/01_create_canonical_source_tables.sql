/*
Purpose: create the canonical, period-independent source contracts.
Inputs: pipeline_config rows loaded by the runner and three validated CSVs.
Output grain: one row per practice code and reporting month in each source.
Failure condition: source headers, values, provenance ownership or duplicate keys
are rejected by the runner before later SQL is executed.
*/

PRAGMA foreign_keys = ON;

CREATE TABLE pipeline_config (
    property_name TEXT PRIMARY KEY,
    property_value TEXT NOT NULL
);

CREATE TABLE source_provenance (
    dataset TEXT NOT NULL,
    component TEXT NOT NULL,
    observation_month TEXT NOT NULL,
    publication_release_month TEXT NOT NULL,
    publication_page_url TEXT NOT NULL,
    selected INTEGER NOT NULL CHECK (selected IN (0, 1)),
    source_filename TEXT NOT NULL,
    sha256 TEXT NOT NULL,
    notes TEXT,
    PRIMARY KEY (dataset, component, observation_month, publication_release_month, source_filename)
);

CREATE TABLE online_consultation_source (
    practice_code_standardised TEXT NOT NULL,
    reporting_month TEXT NOT NULL,
    registered_patients REAL,
    total_submissions REAL,
    clinical_submissions REAL,
    administrative_submissions REAL,
    other_unknown_submissions REAL,
    participation_flag INTEGER,
    unknown_supplier_flag INTEGER,
    PRIMARY KEY (practice_code_standardised, reporting_month)
);

CREATE TABLE appointment_activity_source (
    practice_code_standardised TEXT NOT NULL,
    reporting_month TEXT NOT NULL,
    total_appointments REAL,
    attended REAL,
    dna REAL,
    status_unknown REAL,
    face_to_face REAL,
    telephone REAL,
    video_online REAL,
    home_visit REAL,
    mode_unknown REAL,
    mode_other REAL,
    same_day REAL,
    one_day REAL,
    two_to_seven_days REAL,
    eight_to_fourteen_days REAL,
    fifteen_to_twenty_one_days REAL,
    twenty_two_to_twenty_eight_days REAL,
    more_than_twenty_eight_days REAL,
    booking_unknown REAL,
    booking_other REAL,
    PRIMARY KEY (practice_code_standardised, reporting_month)
);

CREATE TABLE cloud_telephony_source (
    practice_code_standardised TEXT NOT NULL,
    reporting_month TEXT NOT NULL,
    inbound_calls REAL,
    answered_calls REAL,
    missed_calls REAL,
    ivr_exits REAL,
    callback_requests REAL,
    mapping_valid INTEGER,
    integrity_gap_flag INTEGER,
    PRIMARY KEY (practice_code_standardised, reporting_month)
);
