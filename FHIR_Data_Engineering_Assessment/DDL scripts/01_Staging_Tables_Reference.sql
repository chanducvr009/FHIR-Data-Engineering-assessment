/*
Reference DDL for the Fabric Warehouse staging tables.
The live Dataflow destinations already exist. Compare these types with the
current INFORMATION_SCHEMA output before using this script in another workspace.
*/

CREATE TABLE dbo.stg_patient
(
    resource_url          VARCHAR(1000) NULL,
    resource_type         VARCHAR(50) NULL,
    patient_id            VARCHAR(100) NULL,
    version_id            VARCHAR(100) NULL,
    last_updated          DATETIME2(6) NULL,
    meta_source           VARCHAR(1000) NULL,
    identifier_system     VARCHAR(500) NULL,
    identifier_value      VARCHAR(200) NULL,
    is_active             BIT NULL,
    name_use              VARCHAR(50) NULL,
    last_name             VARCHAR(200) NULL,
    first_name            VARCHAR(200) NULL,
    gender                VARCHAR(30) NULL,
    birth_date            DATE NULL,
    extraction_timestamp  DATETIME2(6) NULL
);

CREATE TABLE dbo.stg_encounter_v2
(
    resource_url          VARCHAR(1000) NULL,
    resource_type         VARCHAR(50) NULL,
    encounter_id          VARCHAR(100) NULL,
    patient_id            VARCHAR(100) NULL,
    status                VARCHAR(50) NULL,
    encounter_class       VARCHAR(100) NULL,
    service_type          VARCHAR(200) NULL,
    service_code          VARCHAR(200) NULL,
    start_date            DATETIME2(6) NULL,
    end_date              DATETIME2(6) NULL,
    version_id            VARCHAR(100) NULL,
    last_updated          DATETIME2(6) NULL,
    extraction_timestamp  DATETIME2(6) NULL
);

CREATE TABLE dbo.stg_observation
(
    resource_url          VARCHAR(1000) NULL,
    resource_type         VARCHAR(50) NULL,
    observation_id        VARCHAR(100) NULL,
    patient_id            VARCHAR(100) NULL,
    status                VARCHAR(50) NULL,
    category_code         VARCHAR(200) NULL,
    observation_code      VARCHAR(200) NULL,
    observation_system    VARCHAR(500) NULL,
    observation_name      VARCHAR(500) NULL,
    value_numeric         DECIMAL(18,6) NULL,
    value_text            VARCHAR(4000) NULL,
    value_unit            VARCHAR(100) NULL,
    value_code            VARCHAR(200) NULL,
    effective_date        DATETIME2(6) NULL,
    version_id            VARCHAR(100) NULL,
    last_updated          DATETIME2(6) NULL,
    extraction_timestamp  DATETIME2(6) NULL
);

CREATE TABLE dbo.stg_condition
(
    resource_url          VARCHAR(1000) NULL,
    resource_type         VARCHAR(50) NULL,
    condition_id          VARCHAR(100) NULL,
    patient_id            VARCHAR(100) NULL,
    clinical_status       VARCHAR(100) NULL,
    verification_status   VARCHAR(100) NULL,
    condition_code        VARCHAR(200) NULL,
    condition_system      VARCHAR(500) NULL,
    condition_name        VARCHAR(500) NULL,
    onset_date            DATETIME2(6) NULL,
    recorded_date         DATETIME2(6) NULL,
    version_id            VARCHAR(100) NULL,
    last_updated          DATETIME2(6) NULL,
    extraction_timestamp  DATETIME2(6) NULL
);
