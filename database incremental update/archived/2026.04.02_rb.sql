/*
 Navicat Premium Data Transfer

 Source Server         : NCZ [Dev]
 Source Server Type    : SQL Server
 Source Server Version : 12009114 (12.00.9114)
 Source Host           : ncz.database.windows.net:1433
 Source Catalog        : nczdev
 Source Schema         : portal

 Target Server Type    : SQL Server
 Target Server Version : 12009114 (12.00.9114)
 File Encoding         : 65001

 Date: 04/04/2026 09:25:31
*/


-- ----------------------------
-- procedure structure for spCertificationBlueAward_Save
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spCertificationBlueAward_Save]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spCertificationBlueAward_Save]
GO

CREATE PROCEDURE [portal].[spCertificationBlueAward_Save]
  @dimFormId int,
  @submissionId int
AS
BEGIN
  -- Add Blue Award Certification

  DECLARE @notes varchar(200);
  Declare @certSubmissionId int;
  
  if(@dimFormId = 29) -- Blue Award
    begin
      SELECT @notes = responseData FROM portal.FormSubmissionResponses 
      WHERE submissionId = @submissionId and questionId = 817; 
                
      INSERT INTO [portal].[CertFormSubmissions] (certId, submissionId, dimFormId, notes, isDraft, dateSubmitted) 
                                          VALUES (0, @submissionId, @dimFormId, @notes, 0, CURRENT_TIMESTAMP);
      
      SET @certSubmissionId = SCOPE_IDENTITY();
      INSERT INTO [portal].[BlueAwardCertification] (certSubmissionId, status, progId) 
                                           VALUES (@certSubmissionId, 2, 1); -- Data collection Complete
                                           
      -- Set SubmissionId for Document in FormSubmissionDocuments table as Blue Award form will have SubmissionId=0 when document uploaded
      
      DROP TABLE IF EXISTS #FileQuestionResponses;
      
      Select fsr.submissionId, df.sourceId as formId, fsr.questionId, fsr.responseData
      into #FileQuestionResponses
      from Dimension.Form as df
      INNER JOIN portal.FormQuestions as fq on (fq.formId = df.sourceId and fq.questionType = 'file')
      INNER JOIN portal.FormSubmissionResponses as fsr on (fsr.submissionId = @submissionId and fsr.questionId = fq.questionId)
      Where df.id = @dimFormId;

      UPDATE fsd
      SET fsd.submissionId = t.submissionId
      FROM portal.formSubmissionDocuments AS fsd
      INNER JOIN #FileQuestionResponses AS t
          CROSS APPLY OPENJSON(t.responseData)
              WITH (documentId INT '$') AS j
          ON fsd.documentId = j.documentId
      Where fsd.formId = t.formId and fsd.questionId = t.questionId;
      
      DROP TABLE IF EXISTS #FileQuestionResponses;
      
      select @certSubmissionId as certSubmissionId;
      
    end

END
GO


-- ----------------------------
-- procedure structure for spToken_Validate
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spToken_Validate]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spToken_Validate]
GO

CREATE PROCEDURE [portal].[spToken_Validate]
    @tokenType NVARCHAR(100),   -- widened to hold comma-separated values
    @tokenKey  NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        tokenId,
        tokenKey,
        tokenType,
        certId,
        locationId,
        dimFormId,
        CASE 
            WHEN activeTo IS NULL  THEN 0
            WHEN activeTo >= GETDATE() THEN 0
            ELSE 1
        END AS isExpired,
        isActive,
        properties
    FROM [portal].[Tokens]
    WHERE tokenKey = @tokenKey
      AND (
            @tokenType IS NULL                          -- no filter → return all types
            OR tokenType IN (
                SELECT TRIM(value)
                FROM STRING_SPLIT(@tokenType, ',')
            )
          );
END
GO

