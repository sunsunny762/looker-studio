IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[portal].[spJotformViewDetails_Get]') AND type IN (N'P', N'PC'))
    DROP PROCEDURE [portal].[spJotformViewDetails_Get];
GO

CREATE PROCEDURE [portal].[spJotformViewDetails_Get]
    @submissionId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        id,
        formId,
        submissionId,
        jotformViewResponse,
        errorMessage,
        isSuccess,
        updatedOn,
        attachment
    FROM portal.JotformViewDetail
    WHERE submissionId = @submissionId
    ORDER BY
        CASE
            WHEN ISNULL(isSuccess, 0) = 1 AND jotformViewResponse IS NOT NULL THEN 0
            ELSE 1
        END,
        updatedOn DESC,
        id DESC;
END;
GO
