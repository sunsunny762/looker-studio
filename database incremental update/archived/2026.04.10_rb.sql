-- =============================================================================
-- NCZ Cart Payment -- spFormSubmission_UpdateStatus: derive responses from submissionData
-- Date: 2026-04-10
-- Author: rb
-- Description:
--   Update spFormSubmission_UpdateStatus so that @responses is built directly
--   from the submissionData JSON already stored in portal.FormSubmissions,
--   by joining portal.FormQuestions on questionKey.
--   This removes the dependency on FormSubmissionResponses being pre-populated
--   before status is set to 1 (submitted).
-- =============================================================================

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[portal].[spFormSubmission_UpdateStatus]') AND type = N'P')
    DROP PROCEDURE [portal].[spFormSubmission_UpdateStatus];
GO

CREATE PROCEDURE [portal].[spFormSubmission_UpdateStatus]
    @submissionId   INT,
    @status         INT      -- 0=draft, 1=submitted, 2=pending-payment
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @formId         INT, @dimFormId int;
    DECLARE @userId         INT;
    DECLARE @submissionData NVARCHAR(MAX);
    DECLARE @responses      NVARCHAR(MAX);

    -- Step 1: Update the status in FormSubmissions
    UPDATE [portal].[FormSubmissions]
    SET    [status]    = @status,
           [updatedAt] = SYSDATETIME()
    WHERE  [submissionId] = @submissionId;

    -- Step 2: When marking as submitted, also finalise the linked submission table
    IF @status = 1
    BEGIN
        -- Fetch submission context needed by child SPs

        SELECT @formId = [formId], @userId = [userId], @submissionData = [submissionData], @dimFormId = df.id
        FROM   [portal].[FormSubmissions] as fs 
        INNER JOIN Dimension.Form as df on (fs.formId = df.sourceId and df.dataSourceId = 2)
        WHERE  [submissionId] = @submissionId;
        
        -- Build @responses from submissionData by matching questionKey → questionId.
        -- OPENJSON on a flat JSON object yields rows of (key, value, type) where type is:
        --   0=null, 1=string, 2=number, 3=true/false, 4=array, 5=object
        -- Arrays and objects are kept as-is (their JSON string becomes responseValue).
        IF @submissionData IS NOT NULL AND ISJSON(@submissionData) = 1
        BEGIN
            SELECT @responses = (
                SELECT
                    q.[questionId],
                    kv.[value]   AS [responseValue],
                    CASE kv.[type]
                        WHEN 0 THEN 'null'
                        WHEN 1 THEN 'string'
                        WHEN 2 THEN 'number'
                        WHEN 3 THEN 'boolean'
                        WHEN 4 THEN 'array'
                        WHEN 5 THEN 'object'
                        ELSE        'string'
                    END          AS [responseDataType]
                FROM  OPENJSON(@submissionData)   kv
                INNER JOIN [portal].[FormQuestions] q
                    ON  q.[questionKey] = kv.[key] COLLATE DATABASE_DEFAULT
                    AND q.[formId]      = @formId
                    AND q.[isActive]    = 1
                WHERE kv.[value] IS NOT NULL
                FOR JSON PATH
            );
        END;

        -- Cert form: delegate to spFormSubmission_Save which handles
        -- CertFormSubmissions update, response records, and audit trail.
        -- Reconstruct the responses JSON from the already-saved response rows.

        EXEC [portal].[spFormSubmission_Save]
              @formId        = @formId,
              @submissionId  = @submissionId,
              @userId        = @userId,
              @submissionData = @submissionData,
              @responses     = @responses,
              @status        = 1;
                
        IF NOT EXISTS (SELECT 1 FROM [portal].[PublicFormSubmissions] WHERE [submissionId] = @submissionId)
        BEGIN
            -- Public form: create the PublicFormSubmissions record if not already present.
            -- formId is used as dimFormId (they reference the same NCZ form dimension).
            EXEC [portal].[spPublicFormSubmission_Save]
                  @dimFormId    = @dimFormId,
                  @submissionId = @submissionId;
        END
        -- else: plain NCZ form submission — FormSubmissions update above is sufficient
    END
END
GO
PRINT 'Updated procedure portal.spFormSubmission_UpdateStatus';
GO

PRINT '=== 2026.04.10_rb.sql completed successfully ===';
GO
