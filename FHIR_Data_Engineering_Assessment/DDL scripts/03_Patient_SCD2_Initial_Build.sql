/*
Patient SCD Type 2 initial table build.
Use only in a new/empty deployment. Do not run against the current workspace.
*/

CREATE TABLE dbo.dim_patient
(
    patient_skey BIGINT IDENTITY NOT NULL,
    patient_id VARCHAR(100) NOT NULL,
    name_use VARCHAR(50) NULL,
    last_name VARCHAR(200) NULL,
    first_name VARCHAR(200) NULL,
    gender VARCHAR(30) NULL,
    birth_date DATE NULL,
    is_active BIT NULL,
    identifier_system VARCHAR(500) NULL,
    identifier_value VARCHAR(200) NULL,
    last_updated DATETIME2(6) NULL,
    extraction_timestamp DATETIME2(6) NULL,
    effective_start_date DATETIME2(6) NOT NULL,
    effective_end_date DATETIME2(6) NOT NULL,
    is_current BIT NOT NULL
);

INSERT INTO dbo.dim_patient
(
    patient_id, name_use, last_name, first_name, gender, birth_date,
    is_active, identifier_system, identifier_value, last_updated,
    extraction_timestamp, effective_start_date, effective_end_date, is_current
)
SELECT
    patient_id, name_use, last_name, first_name, gender, birth_date,
    is_active, identifier_system, identifier_value, last_updated,
    extraction_timestamp,
    COALESCE(last_updated, extraction_timestamp, CAST(SYSUTCDATETIME() AS DATETIME2(6))),
    CAST('9999-12-31 23:59:59.999999' AS DATETIME2(6)),
    1
FROM dbo.patient
WHERE patient_id IS NOT NULL
  AND TRIM(patient_id) <> '';
