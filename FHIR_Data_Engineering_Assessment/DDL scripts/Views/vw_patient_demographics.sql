CREATE VIEW dbo.vw_patient_demographics
AS
SELECT
    patient_id,
    name_use,
    first_name,
    last_name,
    gender,
    birth_date,
    is_active,
    identifier_system,
    identifier_value,
    last_updated
FROM dbo.dim_patient
WHERE is_current = 1;
