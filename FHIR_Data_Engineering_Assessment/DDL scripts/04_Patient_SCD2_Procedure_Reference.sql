/*
Reference implementation for dbo.usp_load_dim_patient_scd2.
Compare with the live sys.sql_modules definition before final submission.
*/

CREATE PROCEDURE dbo.usp_load_dim_patient_scd2
AS
BEGIN
    DECLARE @scd_run_time DATETIME2(6) = CAST(SYSUTCDATETIME() AS DATETIME2(6));

    -- Expire current rows when a tracked attribute changes.
    UPDATE d
    SET
        effective_end_date =
            CASE
                WHEN @scd_run_time > d.effective_start_date
                    THEN @scd_run_time
                ELSE DATEADD(MICROSECOND, 1, d.effective_start_date)
            END,
        is_current = 0
    FROM dbo.dim_patient AS d
    INNER JOIN dbo.patient AS s
        ON d.patient_id = s.patient_id
    WHERE d.is_current = 1
      AND
      (
           (d.name_use <> s.name_use OR (d.name_use IS NULL AND s.name_use IS NOT NULL) OR (d.name_use IS NOT NULL AND s.name_use IS NULL))
        OR (d.last_name <> s.last_name OR (d.last_name IS NULL AND s.last_name IS NOT NULL) OR (d.last_name IS NOT NULL AND s.last_name IS NULL))
        OR (d.first_name <> s.first_name OR (d.first_name IS NULL AND s.first_name IS NOT NULL) OR (d.first_name IS NOT NULL AND s.first_name IS NULL))
        OR (d.gender <> s.gender OR (d.gender IS NULL AND s.gender IS NOT NULL) OR (d.gender IS NOT NULL AND s.gender IS NULL))
        OR (d.birth_date <> s.birth_date OR (d.birth_date IS NULL AND s.birth_date IS NOT NULL) OR (d.birth_date IS NOT NULL AND s.birth_date IS NULL))
        OR (d.is_active <> s.is_active OR (d.is_active IS NULL AND s.is_active IS NOT NULL) OR (d.is_active IS NOT NULL AND s.is_active IS NULL))
        OR (d.identifier_system <> s.identifier_system OR (d.identifier_system IS NULL AND s.identifier_system IS NOT NULL) OR (d.identifier_system IS NOT NULL AND s.identifier_system IS NULL))
        OR (d.identifier_value <> s.identifier_value OR (d.identifier_value IS NULL AND s.identifier_value IS NOT NULL) OR (d.identifier_value IS NOT NULL AND s.identifier_value IS NULL))
      );

    -- Insert a new current version for new or changed patients.
    INSERT INTO dbo.dim_patient
    (
        patient_id, name_use, last_name, first_name, gender, birth_date,
        is_active, identifier_system, identifier_value, last_updated,
        extraction_timestamp, effective_start_date, effective_end_date, is_current
    )
    SELECT
        s.patient_id, s.name_use, s.last_name, s.first_name, s.gender, s.birth_date,
        s.is_active, s.identifier_system, s.identifier_value, s.last_updated,
        s.extraction_timestamp,
        CASE
            WHEN EXISTS
            (
                SELECT 1
                FROM dbo.dim_patient h
                WHERE h.patient_id = s.patient_id
                  AND h.is_current = 0
            )
            THEN
            (
                SELECT MAX(h.effective_end_date)
                FROM dbo.dim_patient h
                WHERE h.patient_id = s.patient_id
                  AND h.is_current = 0
            )
            ELSE COALESCE(s.last_updated, s.extraction_timestamp, @scd_run_time)
        END,
        CAST('9999-12-31 23:59:59.999999' AS DATETIME2(6)),
        1
    FROM dbo.patient s
    WHERE s.patient_id IS NOT NULL
      AND TRIM(s.patient_id) <> ''
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.dim_patient c
          WHERE c.patient_id = s.patient_id
            AND c.is_current = 1
      );
END;
