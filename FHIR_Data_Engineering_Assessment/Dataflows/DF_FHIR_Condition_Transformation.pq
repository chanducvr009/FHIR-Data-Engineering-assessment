// Recovered Power Query M query text from the supplied project conversation.
// Compare with the live Dataflow Gen2 query before treating this as an export.

let

    // 1. Connect to Bronze Lakehouse

    Source = Lakehouse.Contents(null),

    Navigation = Source{

        [workspaceId = "8f40633e-2087-4192-ba4f-407df8657ae8"]

    }[Data],

    LakehouseData = Navigation{

        [lakehouseId = "dea856ee-ba34-4c0b-ab8b-36948a8289b3"]

    }[Data],

    Files = LakehouseData{

        [Id = "Files", ItemKind = "Folder"]

    }[Data],

    ConditionFolder = Files{

        [Name = "condition"]

    }[Content],

    ConditionFile = ConditionFolder{

        [Name = "condition_bundle.json"]

    }[Content],

    // 2. Read newline-separated JSON bundles

    JsonLines = Lines.FromBinary(

        ConditionFile,

        null,

        null,

        65001

    ),

    NonEmptyLines = List.Select(

        JsonLines,

        each Text.Trim(_) <> ""

    ),

    ParsedBundles = List.Transform(

        NonEmptyLines,

        each Json.Document(_)

    ),

    // 3. Extract all Bundle entries

    AllEntries = List.Combine(

        List.Transform(

            ParsedBundles,

            each

                if Value.Is(_, type record) then

                    let

                        EntryList = Record.FieldOrDefault(

                            _, "entry", {}

                        )

                    in

                        if Value.Is(EntryList, type list)

                        then EntryList

                        else {}

                else {}

        )

    ),

    // 4. Safe helper functions

    GetField = (v as any, fieldName as text) as any =>

        if Value.Is(v, type record)

        then Record.FieldOrDefault(v, fieldName, null)

        else null,

    GetFirst = (v as any) as any =>

        if Value.Is(v, type list)

            and List.Count(v) > 0

        then v{0}

        else null,

    GetText = (v as any) as nullable text =>

        if v = null

        then null

        else try Text.From(v) otherwise null,

    ToUTC = (v as any) as nullable datetime =>

        if v = null then

            null

        else

            try

                DateTimeZone.RemoveZone(

                    DateTimeZone.ToUtc(

                        DateTimeZone.From(v)

                    )

                )

            otherwise null,

    // 5. Extract Condition records

    ConditionRows = List.Transform(

        AllEntries,

        (entryRecord) =>

            let

                ConditionResource = GetField(

                    entryRecord, "resource"

                ),

                ConditionMeta = GetField(

                    ConditionResource, "meta"

                ),

                ClinicalStatusRecord = GetField(

                    ConditionResource, "clinicalStatus"

                ),

                ClinicalCoding = GetFirst(

                    GetField(

                        ClinicalStatusRecord, "coding"

                    )

                ),

                VerificationRecord = GetField(

                    ConditionResource,

                    "verificationStatus"

                ),

                VerificationCoding = GetFirst(

                    GetField(

                        VerificationRecord, "coding"

                    )

                ),

                ConditionCodeRecord = GetField(

                    ConditionResource, "code"

                ),

                ConditionCoding = GetFirst(

                    GetField(

                        ConditionCodeRecord, "coding"

                    )

                ),

                ConditionSubject = GetField(

                    ConditionResource, "subject"

                ),

                SubjectReference = GetText(

                    GetField(

                        ConditionSubject, "reference"

                    )

                ),

                PatientID =

                    if SubjectReference = null then

                        null

                    else if Text.Contains(

                        SubjectReference, "Patient/"

                    ) then

                        Text.BeforeDelimiter(

                            Text.AfterDelimiter(

                                SubjectReference,

                                "Patient/"

                            ) & "/",

                            "/"

                        )

                    else

                        null,

                CodeText = GetText(

                    GetField(

                        ConditionCodeRecord, "text"

                    )

                ),

                CodeDisplay = GetText(

                    GetField(

                        ConditionCoding, "display"

                    )

                ),

                OnsetValue = GetField(

                    ConditionResource,

                    "onsetDateTime"

                ),

                OnsetPeriod = GetField(

                    ConditionResource,

                    "onsetPeriod"

                ),

                OnsetTimestamp =

                    if OnsetValue <> null then

                        OnsetValue

                    else

                        GetField(

                            OnsetPeriod, "start"

                        )

            in

                [

                    resource_url = GetText(

                        GetField(

                            entryRecord, "fullUrl"

                        )

                    ),

                    resource_type = GetText(

                        GetField(

                            ConditionResource,

                            "resourceType"

                        )

                    ),

                    condition_id = GetText(

                        GetField(

                            ConditionResource, "id"

                        )

                    ),

                    patient_id = PatientID,

                    clinical_status = GetText(

                        GetField(

                            ClinicalCoding, "code"

                        )

                    ),

                    verification_status = GetText(

                        GetField(

                            VerificationCoding, "code"

                        )

                    ),

                    condition_code = GetText(

                        GetField(

                            ConditionCoding, "code"

                        )

                    ),

                    condition_system = GetText(

                        GetField(

                            ConditionCoding, "system"

                        )

                    ),

                    condition_name =

                        if CodeText <> null

                        then CodeText

                        else CodeDisplay,

                    onset_date = ToUTC(

                        OnsetTimestamp

                    ),

                    recorded_date = ToUTC(

                        GetField(

                            ConditionResource,

                            "recordedDate"

                        )

                    ),

                    version_id = GetText(

                        GetField(

                            ConditionMeta, "versionId"

                        )

                    ),

                    last_updated = ToUTC(

                        GetField(

                            ConditionMeta, "lastUpdated"

                        )

                    )

                ]

    ),

    // 6. Convert records to table

    ConditionTable = Table.FromRecords(

        ConditionRows,

        {

            "resource_url",

            "resource_type",

            "condition_id",

            "patient_id",

            "clinical_status",

            "verification_status",

            "condition_code",

            "condition_system",

            "condition_name",

            "onset_date",

            "recorded_date",

            "version_id",

            "last_updated"

        },

        MissingField.UseNull

    ),

    // 7. Set data types

    ChangedTypes = Table.TransformColumnTypes(

        ConditionTable,

        {

            {"resource_url", type text},

            {"resource_type", type text},

            {"condition_id", type text},

            {"patient_id", type text},

            {"clinical_status", type text},

            {"verification_status", type text},

            {"condition_code", type text},

            {"condition_system", type text},

            {"condition_name", type text},

            {"onset_date", type datetime},

            {"recorded_date", type datetime},

            {"version_id", type text},

            {"last_updated", type datetime}

        }

    ),

    // 8. Filter invalid Condition IDs

    ValidConditions = Table.SelectRows(

        ChangedTypes,

        each

            [resource_type] = "Condition"

            and [condition_id] <> null

            and Text.Trim([condition_id]) <> ""

    ),

    // 9. Add extraction timestamp

    AddedTimestamp = Table.AddColumn(

        ValidConditions,

        "extraction_timestamp",

        each DateTimeZone.RemoveZone(

            DateTimeZone.FixedUtcNow()

        ),

        type datetime

    ),

    // 10. Sort latest versions first

    SortedConditions = Table.Sort(

        AddedTimestamp,

        {

            {"last_updated", Order.Descending},

            {"version_id", Order.Descending}

        }

    ),

    // 11. Deduplicate by Condition ID

    DeduplicatedConditions = Table.Distinct(

        Table.Buffer(SortedConditions),

        {"condition_id"}

    )

in

    DeduplicatedConditions
