/*
Initial-build CTAS scripts for the cleaned Silver tables.
Run only in a new/empty Warehouse. Do not run against the existing assessment
workspace because the target tables already contain data.
*/

-- Patient: latest version for each stable FHIR patient_id.
CREATE TABLE dbo.patient
AS
SELECT
    resource_url,
    resource_type,
    patient_id,
    version_id,
    last_updated,
    meta_source,
    identifier_system,
    identifier_value,
    is_active,
    name_use,
    last_name,
    first_name,
    gender,
    birth_date,
    extraction_timestamp
FROM
(
    SELECT *,
        ROW_NUMBER() OVER
        (
            PARTITION BY patient_id
            ORDER BY last_updated DESC, extraction_timestamp DESC
        ) AS rn
    FROM dbo.stg_patient
    WHERE patient_id IS NOT NULL
      AND TRIM(patient_id) <> ''
) AS ranked_patient
WHERE rn = 1;

-- Encounter: latest version for each stable FHIR encounter_id.
-- The current project uses dbo.stg_encounter_v2 as its staging source.
CREATE TABLE dbo.encounter
AS
SELECT
    resource_url,
    resource_type,
    encounter_id,
    patient_id,
    status,
    encounter_class,
    service_type,
    service_code,
    start_date,
    end_date,
    version_id,
    last_updated,
    extraction_timestamp
FROM
(
    SELECT *,
        ROW_NUMBER() OVER
        (
            PARTITION BY encounter_id
            ORDER BY last_updated DESC, extraction_timestamp DESC
        ) AS rn
    FROM dbo.stg_encounter_v2
    WHERE encounter_id IS NOT NULL
      AND TRIM(encounter_id) <> ''
) AS ranked_encounter
WHERE rn = 1;

-- Observation: latest version for each stable FHIR observation_id.
CREATE TABLE dbo.observation
AS
SELECT
    resource_url,
    resource_type,
    observation_id,
    patient_id,
    status,
    category_code,
    observation_code,
    observation_system,
    observation_name,
    value_numeric,
    value_text,
    value_unit,
    value_code,
    effective_date,
    version_id,
    last_updated,
    extraction_timestamp
FROM
(
    SELECT *,
        ROW_NUMBER() OVER
        (
            PARTITION BY observation_id
            ORDER BY last_updated DESC, extraction_timestamp DESC
        ) AS rn
    FROM dbo.stg_observation
    WHERE observation_id IS NOT NULL
      AND TRIM(observation_id) <> ''
      AND resource_type = 'Observation'
) AS ranked_observation
WHERE rn = 1;

-- Condition: latest version for each stable FHIR condition_id.
CREATE TABLE dbo.condition
AS
SELECT
    resource_url,
    resource_type,
    condition_id,
    patient_id,
    clinical_status,
    verification_status,
    condition_code,
    condition_system,
    condition_name,
    onset_date,
    recorded_date,
    version_id,
    last_updated,
    extraction_timestamp
FROM
(
    SELECT *,
        ROW_NUMBER() OVER
        (
            PARTITION BY condition_id
            ORDER BY last_updated DESC, extraction_timestamp DESC
        ) AS rn
    FROM dbo.stg_condition
    WHERE condition_id IS NOT NULL
      AND TRIM(condition_id) <> ''
      AND resource_type = 'Condition'
) AS ranked_condition
WHERE rn = 1;
