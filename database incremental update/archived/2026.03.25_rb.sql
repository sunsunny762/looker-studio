-- ----------------------------
-- Updates: spFormSubmission_Save
-- When files are uploaded before a submission record exists (submissionId=0),
-- link those portal.FormSubmissionDocuments rows to the real submissionId on save/submit.
-- ----------------------------

IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spFormSubmission_Save]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spFormSubmission_Save]
GO

CREATE PROCEDURE [portal].[spFormSubmission_Save]
    @formId INT,
    @submissionId int, 
    @userId int,
    @submissionData NVARCHAR(MAX),
    @responses NVARCHAR(MAX),
    @status int = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @currentDate DATETIME2 = GETDATE();
    DECLARE @action nvarchar(15);
    
    BEGIN TRY
        BEGIN TRANSACTION;

            if not exists (select * from portal.FormSubmissions where submissionId = @submissionId)
              BEGIN
                INSERT into [portal].[FormSubmissions] (formId, userId, submissionData, createdAt, status)
                              values (@formId, @userId, @submissionData, @currentDate, @status);
                              
                SELECT @submissionId = SCOPE_IDENTITY();
                set @action = 'insert';
              END
            else
              BEGIN
                -- Update main submission record
                UPDATE [portal].[FormSubmissions] 
                SET 
                    SubmissionData = @submissionData,
                    UpdatedAt = @currentDate,
                    Status = @status
                WHERE submissionId = @submissionId;
                
                set @action = 'update';
              END

            -- Link orphaned document uploads (submissionId=0) to the actual submission.
            -- Files uploaded before the submission record existed are stored with submissionId=0.
            -- Only considers active file-type questions (FormQuestions.questionType='file', isActive=1).
            -- Plain integer array of documentIds, e.g. "evidenceUpload":[170,169,168,167,166,165,163,162]
            IF @responses IS NOT NULL AND ISJSON(@responses) = 1
            BEGIN
                UPDATE fsd
                SET fsd.submissionId = @submissionId
                FROM portal.FormSubmissionDocuments fsd
                WHERE fsd.submissionId = 0
                  AND fsd.formId = @formId
                  AND fsd.documentId IN (
                      SELECT combined.documentId
                      FROM OPENJSON(@responses) WITH (
                          questionId    INT            '$.questionId',
                          responseValue NVARCHAR(MAX)  '$.responseValue'
                      ) r
                      INNER JOIN portal.FormQuestions fq
                          ON  fq.questionId   = r.questionId
                          AND fq.formId       = @formId
                          AND fq.questionType = 'file'
                          AND fq.isActive     = 1
                      CROSS APPLY (
                          -- plain integer array of documentIds, e.g. [170,169,168,167,166,165,163,162]
                          SELECT TRY_CAST(j.[value] AS INT)
                          FROM OPENJSON(r.responseValue) j
                          WHERE TRY_CAST(j.[value] AS INT) IS NOT NULL
                            AND j.[type] = 2  -- type 2 = number literal
                      ) combined(documentId)
                      WHERE ISJSON(r.responseValue) = 1
                  );
            END;
              
            -- Submitted
            if @status = 1 
            begin 
                -- Delete existing responses
                DELETE FROM [portal].[FormSubmissionResponses] 
                WHERE submissionId = @submissionId;
              
                -- Insert responses
                IF @responses IS NOT NULL
                BEGIN
                    INSERT INTO [portal].[FormSubmissionResponses] 
                    (submissionId, QuestionId, ResponseData, ResponseDataType)
                    SELECT 
                        @submissionId,
                        [QuestionId],
                        [ResponseValue],
                        [ResponseDataType]
                    FROM OPENJSON(@responses)
                    WITH (
                        QuestionId INT '$.questionId',
                        ResponseValue NVARCHAR(MAX) '$.responseValue',
                        ResponseDataType NVARCHAR(50) '$.responseDataType'
                    )
                    Where ResponseValue is not null;
                END;
            
            
                Update portal.CertFormSubmissions
                  set isDraft = 0,
                      isProcessed = 0,
                      userId = @userId, -- who submitted
                      dateSubmitted = @currentDate
                Where submissionId = @submissionId;
                
                set @action = 'submit';
            end;
        
            -- Audit log
            INSERT into portal.FormSubmissionAuditTrail (submissionId, userId, [action], changes, createdAt)
                                                values (@submissionId, @userId, @action, @submissionData, @currentDate);
        
        COMMIT TRANSACTION;
        
        -- Return the submission ID
        SELECT @submissionId AS submissionId;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
