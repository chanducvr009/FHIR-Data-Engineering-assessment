/*
Reference validation procedure.
The live procedure definition should be exported and compared before submission.
This procedure returns counts for key data-quality checks.
*/

CREATE PROCEDURE dbo.usp_validate_fhir_pipeline
AS
BEGIN
    SELECT 'Patient null business keys' AS check_name, COUNT(*) AS issue_count
    FROM dbo.patient
    WHERE patient_id IS NULL OR TRIM(patient_id) = ''

    UNION ALL
    SELECT 'Encounter null business keys', COUNT(*)
    FROM dbo.encounter
    WHERE encounter_id IS NULL OR TRIM(encounter_id) = ''

    UNION ALL
    SELECT 'Observation null business keys', COUNT(*)
    FROM dbo.observation
    WHERE observation_id IS NULL OR TRIM(observation_id) = ''

    UNION ALL
    SELECT 'Condition null business keys', COUNT(*)
    FROM dbo.condition
    WHERE condition_id IS NULL OR TRIM(condition_id) = ''

    UNION ALL
    SELECT 'Patient duplicate current SCD2 rows', COUNT(*)
    FROM
    (
        SELECT patient_id
        FROM dbo.dim_patient
        WHERE is_current = 1
        GROUP BY patient_id
        HAVING COUNT(*) > 1
    ) AS duplicate_current

    UNION ALL
    SELECT 'Invalid Patient SCD2 date ranges', COUNT(*)
    FROM dbo.dim_patient
    WHERE effective_start_date IS NULL
       OR effective_end_date IS NULL
       OR effective_start_date >= effective_end_date;
END;
