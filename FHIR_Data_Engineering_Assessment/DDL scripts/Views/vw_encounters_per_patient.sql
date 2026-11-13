CREATE VIEW dbo.vw_encounters_per_patient
AS
SELECT
    e.patient_id,
    p.first_name,
    p.last_name,
    CASE
        WHEN e.patient_id IS NULL OR LTRIM(RTRIM(e.patient_id)) = ''
            THEN 'Missing Patient ID'
        WHEN p.patient_id IS NULL
            THEN 'Patient Not Found'
        ELSE 'Matched'
    END AS patient_reference_status,
    COUNT(e.encounter_id) AS total_encounters,
    SUM(CASE WHEN LOWER(e.status) = 'finished' THEN 1 ELSE 0 END) AS finished_encounters,
    SUM(CASE WHEN LOWER(e.status) = 'in-progress' THEN 1 ELSE 0 END) AS in_progress_encounters,
    SUM(CASE WHEN LOWER(e.status) = 'arrived' THEN 1 ELSE 0 END) AS arrived_encounters,
    MIN(e.start_date) AS first_encounter_start,
    MAX(e.start_date) AS latest_encounter_start,
    MAX(e.end_date) AS latest_encounter_end
FROM dbo.encounter e
LEFT JOIN dbo.patient p
    ON e.patient_id = p.patient_id
GROUP BY
    e.patient_id,
    p.first_name,
    p.last_name,
    CASE
        WHEN e.patient_id IS NULL OR LTRIM(RTRIM(e.patient_id)) = ''
            THEN 'Missing Patient ID'
        WHEN p.patient_id IS NULL
            THEN 'Patient Not Found'
        ELSE 'Matched'
    END;
