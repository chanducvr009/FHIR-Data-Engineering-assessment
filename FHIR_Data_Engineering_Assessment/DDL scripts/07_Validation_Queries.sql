-- Row counts by layer
SELECT 'stg_patient' AS object_name, COUNT(*) AS row_count FROM dbo.stg_patient
UNION ALL
SELECT 'stg_encounter_v2', COUNT(*) FROM dbo.stg_encounter_v2
UNION ALL
SELECT 'stg_observation', COUNT(*) FROM dbo.stg_observation
UNION ALL
SELECT 'stg_condition', COUNT(*) FROM dbo.stg_condition
UNION ALL
SELECT 'patient', COUNT(*) FROM dbo.patient
UNION ALL
SELECT 'encounter', COUNT(*) FROM dbo.encounter
UNION ALL
SELECT 'observation', COUNT(*) FROM dbo.observation
UNION ALL
SELECT 'condition', COUNT(*) FROM dbo.condition;

-- Null business keys
SELECT 'patient' AS resource_name, COUNT(*) AS null_key_count
FROM dbo.patient WHERE patient_id IS NULL OR TRIM(patient_id) = ''
UNION ALL
SELECT 'encounter', COUNT(*)
FROM dbo.encounter WHERE encounter_id IS NULL OR TRIM(encounter_id) = ''
UNION ALL
SELECT 'observation', COUNT(*)
FROM dbo.observation WHERE observation_id IS NULL OR TRIM(observation_id) = ''
UNION ALL
SELECT 'condition', COUNT(*)
FROM dbo.condition WHERE condition_id IS NULL OR TRIM(condition_id) = '';

-- Duplicate business keys in cleaned tables
SELECT patient_id AS resource_id, COUNT(*) AS duplicate_count
FROM dbo.patient GROUP BY patient_id HAVING COUNT(*) > 1;

SELECT encounter_id AS resource_id, COUNT(*) AS duplicate_count
FROM dbo.encounter GROUP BY encounter_id HAVING COUNT(*) > 1;

SELECT observation_id AS resource_id, COUNT(*) AS duplicate_count
FROM dbo.observation GROUP BY observation_id HAVING COUNT(*) > 1;

SELECT condition_id AS resource_id, COUNT(*) AS duplicate_count
FROM dbo.condition GROUP BY condition_id HAVING COUNT(*) > 1;

-- Patient SCD2 checks
SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN is_current = 1 THEN 1 ELSE 0 END) AS current_records,
    SUM(CASE WHEN is_current = 0 THEN 1 ELSE 0 END) AS historical_records
FROM dbo.dim_patient;

SELECT patient_id, COUNT(*) AS current_record_count
FROM dbo.dim_patient
WHERE is_current = 1
GROUP BY patient_id
HAVING COUNT(*) > 1;

SELECT patient_id, effective_start_date, effective_end_date
FROM dbo.dim_patient
WHERE effective_start_date IS NULL
   OR effective_end_date IS NULL
   OR effective_start_date >= effective_end_date;

-- Reporting view row counts
SELECT 'Patient Demographics' AS check_name, COUNT(*) AS record_count
FROM dbo.vw_patient_demographics
UNION ALL
SELECT 'Encounters Per Patient', COUNT(*)
FROM dbo.vw_encounters_per_patient
UNION ALL
SELECT 'Observation Trends', COUNT(*)
FROM dbo.vw_observation_trends
UNION ALL
SELECT 'Condition Summary', COUNT(*)
FROM dbo.vw_condition_summary;
