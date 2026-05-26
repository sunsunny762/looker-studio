-- =============================================================================
-- NCZ Cart Payment -- spFormSubmission_UpdateStatus enhancement
-- Date: 2026-04-07
-- Author: rb
-- Description:
--   Update spFormSubmission_UpdateStatus so that when setting status = 1
--   (submitted) it also finalises the record in the correct linked table:
--     - portal.CertFormSubmissions  -> via EXEC portal.spFormSubmission_Save
--     - portal.PublicFormSubmissions -> via EXEC portal.spPublicFormSubmission_Save
--   The SP checks which table the submission belongs to and calls the
--   appropriate SP.  If the submission exists in neither it simply updates
--   portal.FormSubmissions (e.g. plain NCZ form submissions).
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

    DECLARE @formId         INT;
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
        SELECT @formId = [formId], @userId = [userId], @submissionData = [submissionData]
        FROM   [portal].[FormSubmissions]
        WHERE  [submissionId] = @submissionId;

        IF EXISTS (SELECT 1 FROM [portal].[CertFormSubmissions] WHERE [submissionId] = @submissionId)
        BEGIN
            -- Cert form: delegate to spFormSubmission_Save which handles
            -- CertFormSubmissions update, response records, and audit trail.
            -- Reconstruct the responses JSON from the already-saved response rows.
            SELECT @responses = (
                SELECT [questionId], [responseData] AS [responseValue], [responseDataType]
                FROM   [portal].[FormSubmissionResponses]
                WHERE  [submissionId] = @submissionId
                FOR JSON PATH
            );

            EXEC [portal].[spFormSubmission_Save]
                @formId        = @formId,
                @submissionId  = @submissionId,
                @userId        = @userId,
                @submissionData = @submissionData,
                @responses     = @responses,
                @status        = 1;
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM [portal].[PublicFormSubmissions] WHERE [submissionId] = @submissionId)
        BEGIN
            -- Public form: create the PublicFormSubmissions record if not already present.
            -- formId is used as dimFormId (they reference the same NCZ form dimension).
            EXEC [portal].[spPublicFormSubmission_Save]
                @dimFormId    = @formId,
                @submissionId = @submissionId;
        END
        -- else: plain NCZ form submission — FormSubmissions update above is sufficient
    END
END
GO
PRINT 'Updated procedure portal.spFormSubmission_UpdateStatus';
GO

PRINT '=== 2026.04.07_rb.sql completed successfully ===';
GO
