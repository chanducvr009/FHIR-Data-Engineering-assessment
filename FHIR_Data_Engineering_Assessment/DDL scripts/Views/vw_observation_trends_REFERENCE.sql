/*
Reference Gold view based on the available dbo.observation columns.
Compare with the deployed view definition before replacing it.
*/
CREATE VIEW dbo.vw_observation_trends
AS
SELECT
    CAST(effective_date AS DATE) AS observation_date,
    observation_code,
    observation_name,
    value_unit,
    COUNT(*) AS observation_count,
    COUNT(DISTINCT patient_id) AS patient_count,
    AVG(value_numeric) AS average_numeric_value,
    MIN(value_numeric) AS minimum_numeric_value,
    MAX(value_numeric) AS maximum_numeric_value
FROM dbo.observation
GROUP BY
    CAST(effective_date AS DATE),
    observation_code,
    observation_name,
    value_unit;
