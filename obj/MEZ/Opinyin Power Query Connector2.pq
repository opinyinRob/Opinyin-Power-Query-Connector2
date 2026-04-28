// This file contains your Data Connector logic
section Opinyin_Power_BI_Connector2;

[DataSource.Kind="Opinyin_Power_BI_Connector2", Publish="Opinyin_Power_BI_Connector2.Publish"]
shared Opinyin_Power_BI_Connector2.Opinyin = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        feedbackTable = Opinyin_Power_BI_Connector2.FeedbackAnalysis(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        classificationsTable = Opinyin_Power_BI_Connector2.FeedbackClassifications(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        levelsTable = Opinyin_Power_BI_Connector2.ClassificationLevels(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        surveyTable = Opinyin_Power_BI_Connector2.SurveyData(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        passthroughTable = Opinyin_Power_BI_Connector2.PassthroughData(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        includeDataExistsTable = Opinyin_Power_BI_Connector2.IncludesDataExists(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        caseIncludeTable = Opinyin_Power_BI_Connector2.CaseIncludes(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        objects = #table(
            {"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"},
            {
                {"Feedback Analysis", "feedback_analysis", feedbackTable, "Table", "Table", true},
                {"Classifications", "classifications", classificationsTable, "Table", "Table", true},
                {"Classification Levels", "classification_levels", levelsTable, "Table", "Table", true},
                {"Survey Data", "survey_data", surveyTable, "Table", "Table", true},
                {"Passthrough Data", "passthrough_data", passthroughTable, "Table", "Table", true},
                {"Includes Data Exists", "includes_data_exists", includeDataExistsTable, "Table", "Table", true},
                {"Case Includes", "case_includes", caseIncludeTable, "Table", "Table", true}
            }
        ),
        navTable = Opinyin_Power_BI_Connector2.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        navTable;

Opinyin_Power_BI_Connector2.OpinyinWithQuery = (optional query as nullable record) =>
    let
        queryRecord = if query = null then [] else query,
        perPageRaw = Record.FieldOrDefault(queryRecord, "per_page", null),
        pageRaw = Record.FieldOrDefault(queryRecord, "page", null),
        includeRaw = Record.FieldOrDefault(queryRecord, "include", null),
        sortRaw = Record.FieldOrDefault(queryRecord, "sort", null),
        startDateRaw = Record.FieldOrDefault(queryRecord, "start_date", null),
        endDateRaw = Record.FieldOrDefault(queryRecord, "end_date", null),
        feedbackTypeRaw = Record.FieldOrDefault(queryRecord, "filter[feedback_type]", null),
        perPageValue = if perPageRaw = null then null else try Number.From(perPageRaw) otherwise null,
        pageValue = if pageRaw = null then null else try Number.From(pageRaw) otherwise null,
        includeValue = if includeRaw = null then null else Text.From(includeRaw),
        sortValue = if sortRaw = null then null else Text.From(sortRaw),
        feedbackTypeValue = if feedbackTypeRaw = null then null else Text.From(feedbackTypeRaw),
        startDateValue = Opinyin_Power_BI_Connector2.NormalizeDate(startDateRaw),
        endDateValue = Opinyin_Power_BI_Connector2.NormalizeDate(endDateRaw),
        output = Opinyin_Power_BI_Connector2.Opinyin(
            perPageValue,
            pageValue,
            includeValue,
            sortValue,
            startDateValue,
            endDateValue,
            feedbackTypeValue
        )
    in
        output;

Opinyin_Power_BI_Connector2.OpinyinWithParameters = (
    startDate as date,
    endDate as date,
    optional feedbackTypes as nullable text,
    optional include as nullable text,
    optional sort as nullable text,
    optional perPage as nullable number,
    optional page as nullable number
) =>
    let
        output = Opinyin_Power_BI_Connector2.Opinyin(
            perPage,
            page,
            include,
            sort,
            startDate,
            endDate,
            feedbackTypes
        )
    in
        output;

Opinyin_Power_BI_Connector2.FeedbackAnalysis = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        data = Opinyin_Power_BI_Connector2.GetFeedbackAnalysisData(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        sourceTable = Table.FromList(data, Splitter.SplitByNothing(), {"feedback_analysis"}, null, ExtraValues.Error),
        expanded =
            if Table.IsEmpty(sourceTable)
            then sourceTable
            else Table.ExpandRecordColumn(
                sourceTable,
                "feedback_analysis",
                {
                    "analysis_id", "feedback", "created_at", "clas_score", "given_score", "suggested_response",
                    "suggested_follow_up_action", "survey_data", "classifications", "passthrough_data", "includes",
                    "includes_data_exists"
                },
                {
                    "analysis_id", "feedback", "created_at", "clas_score", "given_score", "suggested_response",
                    "suggested_follow_up_action", "survey_data", "classifications", "passthrough_data", "includes",
                    "includes_data_exists"
                }
            )
    in
        expanded;

Opinyin_Power_BI_Connector2.FeedbackClassifications = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        feedbackTable = Opinyin_Power_BI_Connector2.FeedbackAnalysis(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        selected = Table.SelectColumns(feedbackTable, {"analysis_id", "classifications"}, MissingField.UseNull),
        expandedList = Table.ExpandListColumn(selected, "classifications"),
        expandedRecord =
            if Table.IsEmpty(expandedList)
            then expandedList
            else Table.ExpandRecordColumn(
                expandedList,
                "classifications",
                {
                    "analysis_id", "classifcation_id", "sentiment", "sentiment_score", "detected_phrase", "phrase_context",
                    "classification_levels"
                },
                {
                    "classification_analysis_id", "classifcation_id", "sentiment", "sentiment_score", "detected_phrase",
                    "phrase_context", "classification_levels"
                }
            )
    in
        expandedRecord;

Opinyin_Power_BI_Connector2.ClassificationLevels = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        classificationsTable = Opinyin_Power_BI_Connector2.FeedbackClassifications(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        selected = Table.SelectColumns(classificationsTable, {"analysis_id", "classifcation_id", "classification_levels"}, MissingField.UseNull),
        expandedList = Table.ExpandListColumn(selected, "classification_levels"),
        expandedRecord =
            if Table.IsEmpty(expandedList)
            then expandedList
            else Table.ExpandRecordColumn(
                expandedList,
                "classification_levels",
                {"level", "category", "classification_id"},
                {"level", "category", "classification_id"}
            )
    in
        expandedRecord;

Opinyin_Power_BI_Connector2.SurveyData = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        feedbackTable = Opinyin_Power_BI_Connector2.FeedbackAnalysis(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        selected = Table.SelectColumns(feedbackTable, {"analysis_id", "survey_data"}, MissingField.UseNull),
        onlyRecords = Table.SelectRows(selected, each Value.Is([survey_data], type record)),
        expanded =
            if Table.IsEmpty(onlyRecords)
            then onlyRecords
            else Table.ExpandRecordColumn(
                onlyRecords,
                "survey_data",
                {"analysis_id", "question_type", "question_id", "question_text", "survey_id", "description"},
                {
                    "survey_analysis_id", "question_type", "question_id", "question_text", "survey_id", "survey_description"
                }
            )
    in
        expanded;

Opinyin_Power_BI_Connector2.PassthroughData = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        feedbackTable = Opinyin_Power_BI_Connector2.FeedbackAnalysis(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        selected = Table.SelectColumns(feedbackTable, {"analysis_id", "passthrough_data"}, MissingField.UseNull),
        onlyRecords = Table.SelectRows(selected, each Value.Is([passthrough_data], type record)),
        expanded =
            if Table.IsEmpty(onlyRecords)
            then onlyRecords
            else Table.ExpandRecordColumn(
                onlyRecords,
                "passthrough_data",
                {
                    "analysis_id", "passthru1", "passthru2", "passthru3", "passthru4", "passthru5", "passthru6",
                    "passthru7", "passthru8", "passthru9", "passthru10", "passthru11", "passthru12", "passthru13",
                    "passthru14", "passthru15", "passthru16", "passthru17", "passthru18", "passthru19", "passthru20"
                },
                {
                    "passthrough_analysis_id", "passthru1", "passthru2", "passthru3", "passthru4", "passthru5", "passthru6",
                    "passthru7", "passthru8", "passthru9", "passthru10", "passthru11", "passthru12", "passthru13",
                    "passthru14", "passthru15", "passthru16", "passthru17", "passthru18", "passthru19", "passthru20"
                }
            )
    in
        expanded;

Opinyin_Power_BI_Connector2.IncludesDataExists = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        feedbackTable = Opinyin_Power_BI_Connector2.FeedbackAnalysis(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        selected = Table.SelectColumns(feedbackTable, {"analysis_id", "includes_data_exists"}, MissingField.UseNull),
        onlyRecords = Table.SelectRows(selected, each Value.Is([includes_data_exists], type record)),
        expanded =
            if Table.IsEmpty(onlyRecords)
            then onlyRecords
            else Table.ExpandRecordColumn(
                onlyRecords,
                "includes_data_exists",
                {"case", "lead", "referral"},
                {"has_case", "has_lead", "has_referral"}
            )
    in
        expanded;

Opinyin_Power_BI_Connector2.CaseIncludes = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        feedbackTable = Opinyin_Power_BI_Connector2.FeedbackAnalysis(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        selected = Table.SelectColumns(feedbackTable, {"analysis_id", "includes"}, MissingField.UseNull),
        withCase = Table.AddColumn(
            selected,
            "case_include",
            each if Value.Is([includes], type record) then Record.FieldOrDefault([includes], "case", null) else null
        ),
        recordsOnly = Table.SelectRows(withCase, each Value.Is([case_include], type record)),
        expanded =
            if Table.IsEmpty(recordsOnly)
            then recordsOnly
            else Table.ExpandRecordColumn(
                recordsOnly,
                "case_include",
                {"analysis_id", "confidence", "suggested_escalation"},
                {"case_analysis_id", "case_confidence", "suggested_escalation"}
            ),
        cleaned = Table.RemoveColumns(expanded, {"includes"})
    in
        cleaned;

Opinyin_Power_BI_Connector2.GetFeedbackAnalysisData = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) as list =>
    let
        allowedIncludeValues = {"case", "lead", "referral"},
        allowedFeedbackTypeValues = {"case", "lead", "referral"},
        allowedSortValues = {"analysis_id", "date"},
        perPageValue = if perPage = null then null else Number.RoundDown(perPage),
        includeValue = Opinyin_Power_BI_Connector2.ValidateCsvTokens(include, allowedIncludeValues, "include", false),
        sortValue = Opinyin_Power_BI_Connector2.ValidateCsvTokens(sort, allowedSortValues, "sort", true),
        feedbackTypeValue = Opinyin_Power_BI_Connector2.ValidateCsvTokens(feedbackTypes, allowedFeedbackTypeValues, "filter[feedback_type]", false),
        startDateValue = startDate,
        endDateValue = endDate,
        _dateRangeValidated =
            if startDateValue <> null and endDateValue <> null and endDateValue < startDateValue
            then
                error Error.Record(
                    "InvalidDateRange",
                    "The end_date must be greater than or equal to start_date.",
                    [
                        start_date = Date.ToText(startDateValue, "yyyy-MM-dd"),
                        end_date = Date.ToText(endDateValue, "yyyy-MM-dd")
                    ]
                )
            else
                true,
        query0 = [],
        query1 = if includeValue = null then query0 else Record.AddField(query0, "include", includeValue),
        query2 = if sortValue = null then query1 else Record.AddField(query1, "sort", sortValue),
        query3 = if startDateValue = null then query2 else Record.AddField(query2, "start_date", Date.ToText(startDateValue, "yyyy-MM-dd")),
        query4 = if endDateValue = null then query3 else Record.AddField(query3, "end_date", Date.ToText(endDateValue, "yyyy-MM-dd")),
        baseQuery = if feedbackTypeValue = null then query4 else Record.AddField(query4, "filter[feedback_type]", feedbackTypeValue),
        withPerPage =
            if perPageValue = null
            then baseQuery
            else Record.AddField(baseQuery, "per_page", Text.From(if perPageValue < 1 then 1 else perPageValue)),
        validatedQuery = if _dateRangeValidated then withPerPage else withPerPage,
        queryRecord =
            if page = null
            then validatedQuery
            else Record.AddField(validatedQuery, "page", Text.From(Number.RoundDown(page))),
        firstPage = Opinyin_Power_BI_Connector2.GetFeedbackAnalysisPage("https://api2sandbox.opinyin.com/feedback-analysis", queryRecord),
        allRows = Opinyin_Power_BI_Connector2.GetAllPages(firstPage)
    in
        allRows;

Opinyin_Power_BI_Connector2.GetAllPages = (pageResponse as record) as list =>
    let
        currentRows = try pageResponse[data] otherwise {},
        nextUrl = try pageResponse[next_page_url] otherwise null,
        nextRows =
            if nextUrl = null
            then {}
            else @Opinyin_Power_BI_Connector2.GetAllPages(Opinyin_Power_BI_Connector2.GetFeedbackAnalysisPage(nextUrl, null)),
        combined = List.Combine({currentRows, nextRows})
    in
        combined;

Opinyin_Power_BI_Connector2.GetFeedbackAnalysisPage = (pageUrl as text, optional queryRecord as nullable record) as record =>
    let
        token = Extension.CurrentCredential()[Key],
        requestOptionsBase = [Headers = [Authorization = "Bearer " & token, Accept = "application/json"]],
        requestOptions = if queryRecord = null then requestOptionsBase else Record.AddField(requestOptionsBase, "Query", queryRecord),
        source = Json.Document(Web.Contents(pageUrl, requestOptions))
    in
        source;

Opinyin_Power_BI_Connector2.ValidateCsvTokens = (
    rawValue as nullable text,
    allowedValues as list,
    parameterName as text,
    optional allowSortDirection as nullable logical
) as nullable text =>
    let
        allowDirection = if allowSortDirection = null then false else allowSortDirection,
        sourceText = if rawValue = null then null else Text.Trim(rawValue),
        hasValue = sourceText <> null and sourceText <> "",
        parts = List.Transform(Text.Split(sourceText, ","), each Text.Trim(_)),
        nonEmpty = if hasValue then List.Select(parts, each _ <> "") else {},
        finalParts = if hasValue then nonEmpty else {},
        normalizedForValidation =
            List.Transform(
                finalParts,
                each if allowDirection and Text.StartsWith(_, "-") and Text.Length(_) > 1 then Text.Range(_, 1) else _
            ),
        invalidValues = List.Select(normalizedForValidation, each not List.Contains(allowedValues, _)),
        _validated =
            if hasValue and List.Count(invalidValues) > 0
            then
                error Error.Record(
                    "InvalidQueryParameter",
                    "Invalid value(s) for query parameter '" & parameterName & "': " & Text.Combine(List.Distinct(invalidValues), ", "),
                    [
                        Parameter = parameterName,
                        AllowedValues = Text.Combine(allowedValues, ","),
                        ProvidedValues = Text.Combine(finalParts, ",")
                    ]
                )
            else
                true,
        normalized = if hasValue then Text.Combine(List.Distinct(finalParts), ",") else null
    in
        normalized;

Opinyin_Power_BI_Connector2.NormalizeDate = (rawValue as any) as nullable date =>
    let
        normalized =
            if rawValue = null
            then null
            else if Value.Is(rawValue, type date)
            then rawValue
            else try Date.From(rawValue) otherwise null
    in
        normalized;

// Data Source Kind description
Opinyin_Power_BI_Connector2 = [
    TestConnection = (dataSourcePath) => { "Opinyin_Power_BI_Connector2.Opinyin" },
    Authentication = [
        Key = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
Opinyin_Power_BI_Connector2.Publish = [
    Beta = false,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = Opinyin_Power_BI_Connector2.Icons,
    SourceTypeImage = Opinyin_Power_BI_Connector2.Icons
];

Opinyin_Power_BI_Connector2.Icons = [
    Icon16 = { Extension.Contents("Opinyin_Power_BI_Connector216.png"), Extension.Contents("Opinyin_Power_BI_Connector220.png"), Extension.Contents("Opinyin_Power_BI_Connector224.png"), Extension.Contents("Opinyin_Power_BI_Connector232.png") },
    Icon32 = { Extension.Contents("Opinyin_Power_BI_Connector232.png"), Extension.Contents("Opinyin_Power_BI_Connector240.png"), Extension.Contents("Opinyin_Power_BI_Connector248.png"), Extension.Contents("Opinyin_Power_BI_Connector264.png") }
];

Opinyin_Power_BI_Connector2.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta
        [
            NavigationTable.NameColumn = nameColumn,
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn,
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;
