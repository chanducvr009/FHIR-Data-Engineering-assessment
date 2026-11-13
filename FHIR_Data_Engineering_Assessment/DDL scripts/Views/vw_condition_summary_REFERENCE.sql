/*
Reference Gold view based on the available dbo.condition columns.
Compare with the deployed view definition before replacing it.
*/
CREATE VIEW dbo.vw_condition_summary
AS
SELECT
    condition_code,
    condition_name,
    clinical_status,
    verification_status,
    COUNT(*) AS condition_count,
    COUNT(DISTINCT patient_id) AS patient_count,
    MIN(onset_date) AS earliest_onset_date,
    MAX(onset_date) AS latest_onset_date
FROM dbo.condition
GROUP BY
    condition_code,
    condition_name,
    clinical_status,
    verification_status;
