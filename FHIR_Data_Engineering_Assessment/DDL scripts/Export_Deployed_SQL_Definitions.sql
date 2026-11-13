-- Export current table schemas from the deployed Warehouse.
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE,
    ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- Export deployed view definitions.
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    VIEW_DEFINITION
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'dbo'
ORDER BY TABLE_NAME;

-- Export deployed stored procedure definitions.
SELECT
    s.name AS schema_name,
    o.name AS procedure_name,
    m.definition AS procedure_definition
FROM sys.sql_modules AS m
JOIN sys.objects AS o
    ON m.object_id = o.object_id
JOIN sys.schemas AS s
    ON o.schema_id = s.schema_id
WHERE s.name = 'dbo'
  AND o.type = 'P'
ORDER BY o.name;
