# FHIR Data Engineering Assessment

## Project overview

I built this project in Microsoft Fabric to ingest healthcare data from the public HAPI FHIR R4 API and prepare it for reporting.

The pipeline handles four FHIR resources:

- Patient
- Encounter
- Observation
- Condition

The main pipeline is `PL_FHIR_MAIN`. It copies the API responses into the `LH_FHIR_BRONZE` Lakehouse, transforms the data using Dataflow Gen2, loads the Warehouse tables, maintains Patient history, runs SQL checks and updates the incremental watermark.

**Workspace:** `WS_FHIR_DE_ASSESSMENT`  
**Lakehouse:** `LH_FHIR_BRONZE`  
**Warehouse:** `WH_FHIR_DE`  
**Source API:** `https://hapi.fhir.org/baseR4`

## Architecture in simple terms

1. **HAPI FHIR API** – provides the healthcare resources in FHIR JSON format.
2. **Fabric Pipeline** – controls the order of execution and passes the resource name and watermark to the Copy activity.
3. **Copy activity** – calls the API, follows the Bundle `next` link and saves the original JSON response in the Lakehouse.
4. **Bronze Lakehouse** – keeps the raw API responses so the original data is available.
5. **Dataflow Gen2** – reads the JSON, extracts the required fields, converts data types and removes duplicate resource IDs.
6. **Fabric Warehouse** – stores staging tables, cleaned tables, the Patient dimension and reporting views.
7. **SQL procedures** – update Patient history and run data-quality checks.
8. **Gold views** – provide simple datasets for reporting and Power BI.

The core transformations are done in Dataflow Gen2 and SQL. No Fabric notebook or Databricks notebook is used for the main processing.

## Pipeline flow

`PL_FHIR_MAIN` uses the following flow:

`Lookup_Watermark` → `Set_LastUpdated` → `ForEach_FHIR_Resource` → four Copy iterations → four Dataflows → `SQL_Patient_SCD2` → `SQL_Data_Validation` → `Update_Watermark`

The ForEach list contains Patient, Encounter, Observation and Condition. The loop is configured for sequential processing. The Dataflow activities are connected with success dependencies.

## Incremental load and pagination

The current successful run confirms that the `_lastUpdated` filter is being passed to all four API requests.

The watermark is read from `dbo.etl_watermark`. `Lookup_Watermark` subtracts five minutes from the last successful watermark. `Set_LastUpdated` stores the value in the pipeline variable `vLastUpdated`.

The Copy activity Relative URL resolves to this pattern:

```text
@concat(item(), '?_count=10&_lastUpdated=ge', variables('vLastUpdated'))
```

The latest recorded request used:

```text
?_count=10&_lastUpdated=ge2026-10-31T23:55:00Z
```

Pagination is configured as:

- Rule: `AbsoluteUrl`
- JSONPath: `$.link[1].url`
- Maximum requests: `10`

The five-minute overlap helps avoid missing records around the watermark boundary. The cleaned resource tables deduplicate by the resource business key.

After the SQL validation activity succeeds, `Update_Watermark` advances `dbo.etl_watermark` to the pipeline trigger time. In the latest run, the update affected one row.

**Important:** `_count=10` and `MaxRequestNumber=10` make this a bounded assessment run. It is not a full historical extraction from the public HAPI server.

## Data storage

The raw files are stored by resource in the Lakehouse:

- `Files/patient/patient_bundle.json`
- `Files/encounter/encounter_bundle.json`
- `Files/observation/observation_bundle.json`
- `Files/condition/condition_bundle.json`

The Warehouse objects observed during the build are:

**Staging**
- `dbo.stg_patient`
- `dbo.stg_encounter_v2`
- `dbo.stg_observation`
- `dbo.stg_condition`

**Cleaned**
- `dbo.patient`
- `dbo.encounter`
- `dbo.observation`
- `dbo.condition`

**Patient history**
- `dbo.dim_patient`

**Reporting views**
- `dbo.vw_patient_demographics`
- `dbo.vw_encounters_per_patient`
- `dbo.vw_observation_trends`
- `dbo.vw_condition_summary`

**Stored procedures**
- `dbo.usp_load_dim_patient_scd2`
- `dbo.usp_validate_fhir_pipeline`

## Patient SCD Type 2

Patient is the entity used for SCD Type 2.

- `patient_id` is the business key.
- `patient_skey` is the surrogate key.
- `effective_start_date` and `effective_end_date` track each version.
- `is_current` identifies the active version.

The incremental procedure expires the current version when tracked Patient attributes change and inserts a new current version. It does not delete the previous version.

A previously captured Warehouse check showed 103 total Patient dimension records: 100 current and 3 historical. The Patient `nhanes-120412` was used to verify that changes create new versions. Different `patient_skey` values are expected for different versions of the same `patient_id`.

## Latest successful pipeline run

The latest supplied activity-run export is from 12 November 2026.

- 14 activity records were reported as Succeeded.
- The ForEach processed 4 resources.
- Each Copy iteration read and copied 10 rows and wrote one JSON file.
- No Copy errors were reported.
- All four Dataflows succeeded.
- `SQL_Patient_SCD2` succeeded.
- `SQL_Data_Validation` succeeded.
- `Update_Watermark` succeeded and affected one row.

The previous watermark returned by Lookup was `2026-10-31T23:55:00Z`. The new watermark written by the pipeline was `2026-11-12T17:42:08.835`.

A separate Warehouse result check showed:

| Check | Rows |
|---|---:|
| `dbo.stg_encounter_v2` | 100 |
| `dbo.vw_patient_demographics` | 100 |
| `dbo.vw_encounters_per_patient` | 82 |
| `dbo.vw_observation_trends` | 29 |
| `dbo.vw_condition_summary` | 32 |
| Patient SCD2 total | 103 |
| Patient SCD2 current | 100 |
| Patient SCD2 historical | 3 |

These are captured test results. The public HAPI server can return different data on a later run.

## How to run the project

1. Open the `WS_FHIR_DE_ASSESSMENT` workspace.
2. Open the existing `PL_FHIR_MAIN` pipeline.
3. Check that `Lookup_Watermark` reads the row for `PL_FHIR_MAIN`.
4. Run the pipeline.
5. Confirm the four Copy iterations and four Dataflows succeed.
6. Confirm both SQL activities succeed.
7. Confirm `Update_Watermark` runs only after validation succeeds.
8. Open `WH_FHIR_DE` and review the four Gold views.



