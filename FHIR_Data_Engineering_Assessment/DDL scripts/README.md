# SQL folder guide

The SQL files are provided for assessment review and reproducible deployment.

- `01_Staging_Tables_Reference.sql` – reference schema for the four staging tables. Compare its data types with the live Warehouse before using it.
- `02_Cleaned_Tables.sql` – CTAS logic for the four cleaned resource tables.
- `03_Patient_SCD2_Initial_Build.sql` – initial Patient dimension setup. Use only in a new/empty deployment.
- `04_Patient_SCD2_Procedure_Reference.sql` – reference implementation of the incremental Patient SCD Type 2 procedure.
- `05_Validation_Procedure_Reference.sql` – reference data-quality checks.
- `Views/` – Gold view definitions. Patient and Encounter views are based on saved project SQL; Observation and Condition views are reference definitions based on the available columns and reporting purpose.
- `06_Watermark_Setup.sql` – watermark control table and initial row.
- `07_Validation_Queries.sql` – optional checks for reviewers. These are not required to be run again if the existing pipeline has already been validated.
- `Export_Deployed_SQL_Definitions.sql` – use this to capture the exact definitions from the live Warehouse.

Do not run initial-build scripts against the current workspace. The live tables and Patient history already exist. Before final submission, replace the reference procedure/view scripts with the exact deployed definitions if they differ.
