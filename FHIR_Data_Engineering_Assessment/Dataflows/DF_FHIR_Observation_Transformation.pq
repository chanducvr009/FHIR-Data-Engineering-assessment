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

    ObservationFolder = Files{

        [Name = "observation"]

    }[Content],

    ObservationFile = ObservationFolder{

        [Name = "observation_bundle.json"]

    }[Content],

    // 2. Read multiple JSON bundles

    JsonLines = Lines.FromBinary(

        ObservationFile,

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

    // 3. Combine entries from all pages

    AllEntries = List.Combine(

        List.Transform(

            ParsedBundles,

            each

                if Value.Is(_, type record) then

                    let

                        Entries = Record.FieldOrDefault(

                            _, "entry", {}

                        )

                    in

                        if Value.Is(Entries, type list)

                        then Entries

                        else {}

                else {}

        )

    ),

    // 4. Helper functions

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

        if v = null

        then null

        else

            try DateTimeZone.RemoveZone(

                DateTimeZone.ToUtc(

                    DateTimeZone.From(v)

                )

            )

            otherwise null,

    // 5. Extract Observation records

    ObservationRows = List.Transform(

        AllEntries,

        (entryRecord) =>

            let

                ObsResource = GetField(

                    entryRecord, "resource"

                ),

                ObsMeta = GetField(

                    ObsResource, "meta"

                ),

                ObsSubject = GetField(

                    ObsResource, "subject"

                ),

                SubjectReference = GetText(

                    GetField(ObsSubject, "reference")

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

                ObsCategory = GetFirst(

                    GetField(ObsResource, "category")

                ),

                CategoryCoding = GetFirst(

                    GetField(ObsCategory, "coding")

                ),

                ObsCode = GetField(

                    ObsResource, "code"

                ),

                CodeCoding = GetFirst(

                    GetField(ObsCode, "coding")

                ),

                ValueQuantity = GetField(

                    ObsResource, "valueQuantity"

                ),

                ValueConcept = GetField(

                    ObsResource, "valueCodeableConcept"

                ),

                ValueConceptCoding = GetFirst(

                    GetField(ValueConcept, "coding")

                ),

                QuantityValue = GetField(

                    ValueQuantity, "value"

                ),

                StringValue = GetField(

                    ObsResource, "valueString"

                ),

                BooleanValue = GetField(

                    ObsResource, "valueBoolean"

                ),

                IntegerValue = GetField(

                    ObsResource, "valueInteger"

                ),

                ObservationValue =

                    if QuantityValue <> null then

                        GetText(QuantityValue)

                    else if StringValue <> null then

                        GetText(StringValue)

                    else if BooleanValue <> null then

                        GetText(BooleanValue)

                    else if IntegerValue <> null then

                        GetText(IntegerValue)

                    else

                        GetText(

                            GetField(ValueConcept, "text")

                        ),

                EffectiveValue =

                    GetField(

                        ObsResource, "effectiveDateTime"

                    ),

                EffectivePeriod = GetField(

                    ObsResource, "effectivePeriod"

                ),

                EffectiveTimestamp =

                    if EffectiveValue <> null then

                        EffectiveValue

                    else

                        GetField(

                            EffectivePeriod, "start"

                        )

            in

                [

                    resource_url = GetText(

                        GetField(entryRecord, "fullUrl")

                    ),

                    resource_type = GetText(

                        GetField(

                            ObsResource, "resourceType"

                        )

                    ),

                    observation_id = GetText(

                        GetField(ObsResource, "id")

                    ),

                    patient_id = PatientID,

                    status = GetText(

                        GetField(ObsResource, "status")

                    ),

                    category_code = GetText(

                        GetField(CategoryCoding, "code")

                    ),

                    observation_code = GetText(

                        GetField(CodeCoding, "code")

                    ),

                    observation_system = GetText(

                        GetField(CodeCoding, "system")

                    ),

                    observation_name =

                        let

                            CodeText = GetText(

                                GetField(ObsCode, "text")

                            ),

                            CodeDisplay = GetText(

                                GetField(CodeCoding, "display")

                            )

                        in

                            if CodeText <> null then

                                CodeText

                            else CodeDisplay,

                    value_numeric =

                        try Number.From(QuantityValue)

                        otherwise null,

                    value_text = ObservationValue,

                    value_unit = GetText(

                        GetField(ValueQuantity, "unit")

                    ),

                    value_code = GetText(

                        GetField(

                            ValueConceptCoding, "code"

                        )

                    ),

                    effective_date = ToUTC(

                        EffectiveTimestamp

                    ),

                    version_id = GetText(

                        GetField(ObsMeta, "versionId")

                    ),

                    last_updated = ToUTC(

                        GetField(ObsMeta, "lastUpdated")

                    )

                ]

    ),

    // 6. Convert to table

    ObservationTable = Table.FromRecords(

        ObservationRows,

        {

            "resource_url",

            "resource_type",

            "observation_id",

            "patient_id",

            "status",

            "category_code",

            "observation_code",

            "observation_system",

            "observation_name",

            "value_numeric",

            "value_text",

            "value_unit",

            "value_code",

            "effective_date",

            "version_id",

            "last_updated"

        },

        MissingField.UseNull

    ),

    // 7. Set data types

    ChangedTypes = Table.TransformColumnTypes(

        ObservationTable,

        {

            {"resource_url", type text},

            {"resource_type", type text},

            {"observation_id", type text},

            {"patient_id", type text},

            {"status", type text},

            {"category_code", type text},

            {"observation_code", type text},

            {"observation_system", type text},

            {"observation_name", type text},

            {"value_numeric", type number},

            {"value_text", type text},

            {"value_unit", type text},

            {"value_code", type text},

            {"effective_date", type datetime},

            {"version_id", type text},

            {"last_updated", type datetime}

        }

    ),

    // 8. Filter invalid Observation IDs

    ValidObservations = Table.SelectRows(

        ChangedTypes,

        each

            [resource_type] = "Observation"

            and [observation_id] <> null

            and Text.Trim([observation_id]) <> ""

    ),

    // 9. Add extraction timestamp

    AddedTimestamp = Table.AddColumn(

        ValidObservations,

        "extraction_timestamp",

        each DateTimeZone.RemoveZone(

            DateTimeZone.FixedUtcNow()

        ),

        type datetime

    ),

    // 10. Sort latest versions first

    SortedObservations = Table.Sort(

        AddedTimestamp,

        {

            {"last_updated", Order.Descending},

            {"version_id", Order.Descending}

        }

    ),

    // 11. Deduplicate by Observation ID

    DeduplicatedObservations = Table.Distinct(

        Table.Buffer(SortedObservations),

        {"observation_id"}

    )

in

    DeduplicatedObservations
