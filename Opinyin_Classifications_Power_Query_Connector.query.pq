// Use this file to write queries to test your data connector
let
    pStartDate = #date(2026, 1, 1),
    pEndDate = #date(2026, 4, 27),
    pFeedbackTypes = "case,lead,referral",
    pInclude = "case,lead,referral",
    pSort = "analysis_id,date",
    pPerPage = 100,
    Source = Opinyin_Classifications_Power_Query_Connector.Opinyin(
        pPerPage,
        null,
        pInclude,
        pSort,
        pStartDate,
        pEndDate,
        pFeedbackTypes
    )
in
    Source