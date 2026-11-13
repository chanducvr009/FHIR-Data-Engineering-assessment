/*
Watermark table used by PL_FHIR_MAIN.
The current workspace already has this table and row.
*/

IF OBJECT_ID('dbo.etl_watermark', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.etl_watermark
    (
        pipeline_name VARCHAR(100) NOT NULL,
        last_successful_watermark DATETIME2(6) NOT NULL
    );
END;

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.etl_watermark
    WHERE pipeline_name = 'PL_FHIR_MAIN'
)
BEGIN
    INSERT INTO dbo.etl_watermark
    (
        pipeline_name,
        last_successful_watermark
    )
    VALUES
    (
        'PL_FHIR_MAIN',
        CAST('2026-11-01T00:00:00' AS DATETIME2(6))
    );
END;

/*
Lookup_Watermark query used by the pipeline:

SELECT
    CONVERT(VARCHAR(23),
        DATEADD(MINUTE, -5, last_successful_watermark),
        126
    ) AS last_successful_watermark
FROM dbo.etl_watermark
WHERE pipeline_name = 'PL_FHIR_MAIN';
*/
