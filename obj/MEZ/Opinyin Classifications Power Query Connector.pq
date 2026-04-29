// This file contains your Data Connector logic
section Opinyin_Classifications_Power_Query_Connector;

[DataSource.Kind="Opinyin_Classifications_Power_Query_Connector", Publish="Opinyin_Classifications_Power_Query_Connector.Publish"]
shared Opinyin_Classifications_Power_Query_Connector.Opinyin = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        feedbackTable = Opinyin_Classifications_Power_Query_Connector.FeedbackAnalysis(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        classificationsTable = Opinyin_Classifications_Power_Query_Connector.FeedbackClassifications(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        levelsTable = Opinyin_Classifications_Power_Query_Connector.ClassificationLevels(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        surveyTable = Opinyin_Classifications_Power_Query_Connector.SurveyData(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        passthroughTable = Opinyin_Classifications_Power_Query_Connector.PassthroughData(perPage, page, include, sort, startDate, endDate, feedbackTypes),        
        caseTable = Opinyin_Classifications_Power_Query_Connector.Case(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        leadTable = Opinyin_Classifications_Power_Query_Connector.Lead(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        referralTable = Opinyin_Classifications_Power_Query_Connector.Referral(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        objects = #table(
            {"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"},
            {
                {"Feedback Analysis", "feedback_analysis", feedbackTable, "Table", "Table", true},
                {"Classifications", "classifications", classificationsTable, "Table", "Table", true},
                {"Classification Levels", "classification_levels", levelsTable, "Table", "Table", true},
                {"Survey Data", "survey_data", surveyTable, "Table", "Table", true},
                {"Passthrough Data", "passthrough_data", passthroughTable, "Table", "Table", true},
                {"Case", "case", caseTable, "Table", "Table", true},
                {"Lead", "lead", leadTable, "Table", "Table", true},
                {"Referral", "referral", referralTable, "Table", "Table", true}

            }
        ),
        navTable = Opinyin_Classifications_Power_Query_Connector.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        navTable;

Opinyin_Classifications_Power_Query_Connector.OpinyinWithQuery = (optional query as nullable record) =>
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
        startDateValue = Opinyin_Classifications_Power_Query_Connector.NormalizeDate(startDateRaw),
        endDateValue = Opinyin_Classifications_Power_Query_Connector.NormalizeDate(endDateRaw),
        output = Opinyin_Classifications_Power_Query_Connector.Opinyin(
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

Opinyin_Classifications_Power_Query_Connector.OpinyinWithParameters = (
    startDate as date,
    endDate as date,
    optional feedbackTypes as nullable text,
    optional include as nullable text,
    optional sort as nullable text,
    optional perPage as nullable number,
    optional page as nullable number
) =>
    let
        output = Opinyin_Classifications_Power_Query_Connector.Opinyin(
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

Opinyin_Classifications_Power_Query_Connector.FeedbackAnalysis = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        data = Opinyin_Classifications_Power_Query_Connector.GetFeedbackAnalysisData(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        sourceTable = Table.FromList(data, Splitter.SplitByNothing(), {"feedback_analysis"}, null, ExtraValues.Error),
        expanded =
            if Table.IsEmpty(sourceTable)
            then sourceTable
            else Table.ExpandRecordColumn(
                sourceTable,
                "feedback_analysis",
                {
                    "analysis_id", "feedback", "created_at", "clas_score", "given_score", "suggested_response",
                    "suggested_follow_up_action", "survey_data", "classifications", "passthrough_data", "includes"
                    
                },
                {
                    "analysis_id", "feedback", "created_at", "clas_score", "given_score", "suggested_response",
                    "suggested_follow_up_action", "survey_data", "classifications", "passthrough_data", "includes"
                }
            )
    in
        expanded;

Opinyin_Classifications_Power_Query_Connector.FeedbackClassifications = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        feedbackTable = Opinyin_Classifications_Power_Query_Connector.FeedbackAnalysis(perPage, page, include, sort, startDate, endDate, feedbackTypes),
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

Opinyin_Classifications_Power_Query_Connector.ClassificationLevels = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        classificationsTable = Opinyin_Classifications_Power_Query_Connector.FeedbackClassifications(perPage, page, include, sort, startDate, endDate, feedbackTypes),
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

Opinyin_Classifications_Power_Query_Connector.SurveyData = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        feedbackTable = Opinyin_Classifications_Power_Query_Connector.FeedbackAnalysis(perPage, page, include, sort, startDate, endDate, feedbackTypes),
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

Opinyin_Classifications_Power_Query_Connector.PassthroughData = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        feedbackTable = Opinyin_Classifications_Power_Query_Connector.FeedbackAnalysis(perPage, page, include, sort, startDate, endDate, feedbackTypes),
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


Opinyin_Classifications_Power_Query_Connector.Case = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        feedbackTable = Opinyin_Classifications_Power_Query_Connector.FeedbackAnalysis(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        selected = Table.SelectColumns(feedbackTable, {"analysis_id", "includes", "feedback"}, MissingField.UseNull),
        withCase = Table.AddColumn(
            selected,
            "case",
            each if Value.Is([includes], type record) then Record.FieldOrDefault([includes], "case", null) else null
        ),
        recordsOnly = Table.SelectRows(withCase, each Value.Is([case_include], type record)),
        expanded =
            if Table.IsEmpty(recordsOnly)
            then recordsOnly
            else Table.ExpandRecordColumn(
                recordsOnly,
                "case",
                {"Analysis ID", "Confidence",  "Feedback", "Case Reason", "Suggested Response"},
                {"analysis_id", "confidence", "feedback", "reason","suggested_follow_up"}
            ),
        cleaned = Table.RemoveColumns(expanded, {"includes"})
    in
        cleaned;


Opinyin_Classifications_Power_Query_Connector.Lead = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        feedbackTable = Opinyin_Classifications_Power_Query_Connector.FeedbackAnalysis(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        selected = Table.SelectColumns(feedbackTable, {"analysis_id", "includes", "feedback"}, MissingField.UseNull),
        withLead = Table.AddColumn(
            selected,
            "lead",
            each if Value.Is([includes], type record) then Record.FieldOrDefault([includes], "lead", null) else null
        ),
        recordsOnly = Table.SelectRows(withLead, each Value.Is([lead], type record)),
        expanded =
            if Table.IsEmpty(recordsOnly)
            then recordsOnly
            else Table.ExpandRecordColumn(
                recordsOnly,
                "case_include",
                {"Analysis ID", "Case Confidence",  "Feedback", "Reason", "Suggested Response"},
                {"analysis_id", "confidence", "feedback", "reason","suggested_escalation"}
            ),
        cleaned = Table.RemoveColumns(expanded, {"includes"})
    in
        cleaned;

Opinyin_Classifications_Power_Query_Connector.Referral = (
    optional perPage as nullable number,
    optional page as nullable number,
    optional include as nullable text,
    optional sort as nullable text,
    optional startDate as nullable date,
    optional endDate as nullable date,
    optional feedbackTypes as nullable text
) =>
    let
        feedbackTable = Opinyin_Classifications_Power_Query_Connector.FeedbackAnalysis(perPage, page, include, sort, startDate, endDate, feedbackTypes),
        selected = Table.SelectColumns(feedbackTable, {"analysis_id", "includes", "feedback"}, MissingField.UseNull),
        withrefferals = Table.AddColumn(
            selected,
            "refferal",
            each if Value.Is([includes], type record) then Record.FieldOrDefault([includes], "refferal", null) else null
        ),
        recordsOnly = Table.SelectRows(withrefferals, each Value.Is([refferals_include], type record)),
        expanded =
            if Table.IsEmpty(recordsOnly)
            then recordsOnly
            else Table.ExpandRecordColumn(
                recordsOnly,
                "refferal",
                {"Analysis ID", "Confidence",  "Feedback", "Reason", "Suggested Response"},
                {"analysis_id", "confidence", "feedback", "reason","suggested_follow_up"}
            ),
        cleaned = Table.RemoveColumns(expanded, {"includes"})
    in
        cleaned;

Opinyin_Classifications_Power_Query_Connector.GetFeedbackAnalysisData = (
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
        includeValue = Opinyin_Classifications_Power_Query_Connector.ValidateCsvTokens(include, allowedIncludeValues, "include", false),
        sortValue = Opinyin_Classifications_Power_Query_Connector.ValidateCsvTokens(sort, allowedSortValues, "sort", true),
        feedbackTypeValue = Opinyin_Classifications_Power_Query_Connector.ValidateCsvTokens(feedbackTypes, allowedFeedbackTypeValues, "filter[feedback_type]", false),
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
        firstPage = Opinyin_Classifications_Power_Query_Connector.GetFeedbackAnalysisPage("https://api2sandbox.opinyin.com/feedback-analysis", queryRecord),
        allRows = Opinyin_Classifications_Power_Query_Connector.GetAllPages(firstPage)
    in
        allRows;

Opinyin_Classifications_Power_Query_Connector.GetAllPages = (pageResponse as record) as list =>
    let
        currentRows = try pageResponse[data] otherwise {},
        nextUrl = try pageResponse[next_page_url] otherwise null,
        nextRows =
            if nextUrl = null
            then {}
            else @Opinyin_Classifications_Power_Query_Connector.GetAllPages(Opinyin_Classifications_Power_Query_Connector.GetFeedbackAnalysisPage(nextUrl, null)),
        combined = List.Combine({currentRows, nextRows})
    in
        combined;

Opinyin_Classifications_Power_Query_Connector.GetFeedbackAnalysisPage = (pageUrl as text, optional queryRecord as nullable record) as record =>
    let
        token = Extension.CurrentCredential()[Key],
        requestOptionsBase = [Headers = [Authorization = "Bearer " & token, Accept = "application/json"]],
        requestOptions = if queryRecord = null then requestOptionsBase else Record.AddField(requestOptionsBase, "Query", queryRecord),
        source = Json.Document(Web.Contents(pageUrl, requestOptions))
    in
        source;

Opinyin_Classifications_Power_Query_Connector.ValidateCsvTokens = (
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

Opinyin_Classifications_Power_Query_Connector.NormalizeDate = (rawValue as any) as nullable date =>
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
Opinyin_Classifications_Power_Query_Connector = [
    TestConnection = (dataSourcePath) => { "Opinyin_Classifications_Power_Query_Connector.Opinyin" },
    Authentication = [
        Key = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
Opinyin_Classifications_Power_Query_Connector.Publish = [
    Beta = false,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = Opinyin_Classifications_Power_Query_Connector.Icons,
    SourceTypeImage = Opinyin_Classifications_Power_Query_Connector.Icons
];

Opinyin_Classifications_Power_Query_Connector.Icons = [
    Icon16 = { Extension.Contents("Opinyin_Classifications_Power_Query_Connector16.png"), Extension.Contents("Opinyin_Classifications_Power_Query_Connector20.png"), Extension.Contents("Opinyin_Classifications_Power_Query_Connector24.png"), Extension.Contents("Opinyin_Classifications_Power_Query_Connector32.png") },
    Icon32 = { Extension.Contents("Opinyin_Classifications_Power_Query_Connector32.png"), Extension.Contents("Opinyin_Classifications_Power_Query_Connector40.png"), Extension.Contents("Opinyin_Classifications_Power_Query_Connector48.png"), Extension.Contents("Opinyin_Classifications_Power_Query_Connector64.png") }
];

Opinyin_Classifications_Power_Query_Connector.ToNavigationTable = (
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
