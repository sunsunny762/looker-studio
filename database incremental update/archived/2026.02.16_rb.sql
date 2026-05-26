/*
 Navicat Premium Data Transfer

 Source Server         : NCZ [Dev]
 Source Server Type    : SQL Server
 Source Server Version : 12001017 (12.00.1017)
 Source Host           : ncz.database.windows.net:1433
 Source Catalog        : nczdev
 Source Schema         : portal

 Target Server Type    : SQL Server
 Target Server Version : 12001017 (12.00.1017)
 File Encoding         : 65001

 Date: 16/02/2026 16:23:33
*/

ALTER TABLE [portal].[Certification] ADD [emissionProfileId] int NULL
Go
ALTER TABLE [portal].[Certification] ADD [revenue] DECIMAL(18, 0) NULL
GO
ALTER TABLE [portal].[Company] ALTER COLUMN [logo] nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
Go

-- ----------------------------
-- procedure structure for spCertification_Save
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spCertification_Save]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spCertification_Save]
GO

CREATE PROCEDURE [portal].[spCertification_Save]
   @certId INT = NULL,
    @companyId INT,
    @progId INT,
    @startDate DATETIME2(7),
    @refNumber NVARCHAR(25),
    @status INT,
    @description NVARCHAR(255),
    @certificationTaskId NVARCHAR(25),
    @emissionProfileId int,
    @revenue decimal(18,0),
		@userId INT = NULL
AS
BEGIN

  SET NOCOUNT ON;

  IF @certId IS NULL
    BEGIN
        INSERT INTO portal.certification (
            companyId, progId, startDate, endDate, status, refNumber, emissionProfileId, revenue,
            description, certificationTaskId, certYear, isDeleted
        )
        VALUES (
            @companyId, @progId, @startDate, DATEADD(DAY, -1, DATEADD(YEAR, 1, @startDate)), @status, @refNumber, @emissionProfileId, @revenue,
            @description, @certificationTaskId, YEAR(@startDate), 0
        );
        
        SET @certId = (SELECT SCOPE_IDENTITY());
    END
    ELSE
    BEGIN
        UPDATE portal.certification
        SET 
            companyId = @companyId,
            progId = @progId,
            startDate = @startDate,
            endDate = DATEADD(DAY, -1, DATEADD(YEAR, 1, @startDate)),
            status = @status,
            refNumber = @refNumber,
            emissionProfileId = @emissionProfileId, 
            revenue = @revenue,
            description = @description,
            certificationTaskId = @certificationTaskId,
            certYear = YEAR(@startDate)
        WHERE certId = @certId;
    END
		
		IF @certId IS NOT NULL
    BEGIN
        EXEC [portal].[spCertificationStatusHistory_Save]
            @companyId = @companyId,
            @certId = @certId,
            @status = @status,
            @userId = @userId;
    END

    if @certId is Not NULL -- return added/updated certification data to frontend to show in grid etc
    BEGIN
      exec portal.spCertification_Get @certId;
    END

END;
GO


-- ----------------------------
-- procedure structure for spCompany_Save
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spCompany_Save]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spCompany_Save]
GO

CREATE PROCEDURE [portal].[spCompany_Save]
    @companyId int,
    @companyName NVARCHAR(100),
    @email NVARCHAR(50),
    @registrationNumber NVARCHAR(100),
    @phone NVARCHAR(20),
    @address NVARCHAR(200),
    @industryType INT,
    @industryTypeOther NVARCHAR(100),
    @website NVARCHAR(100),
    @contactName NVARCHAR(50),
    @jobTitle NVARCHAR(75),
    @status INT, 
    @logo NVARCHAR(MAX),
    @countryId INT,
    @nczCustomerDirectory bit,
    @description nvarchar(300) = null,
    @linkedInPage nvarchar(100) = null,
    @locationCnt INT = 1,
    @companyTaskId NVARCHAR(15) = null,
    @personTaskId NVARCHAR(15) = null,
    @currency nvarchar(3)
AS
BEGIN
  SET NOCOUNT ON;
  
  if @companyId is NULL
    BEGIN
      INSERT INTO portal.Company 
      (companyName, email, registrationNumber, phone, address, industryType, industryTypeOther, website, currency,
       contactName, jobTitle, status, logo, countryId, nczCustomerDirectory, linkedInPage, description, locationCnt, companyTaskId, personTaskId, dateCreated)
      VALUES 
      (@companyName, @email, @registrationNumber, @phone, @address, @industryType, @industryTypeOther, @website, @currency,
       @contactName, @jobTitle, @status, @logo, @countryId, @nczCustomerDirectory, @linkedInPage, @description, @locationCnt, @companyTaskId, @personTaskId, CURRENT_TIMESTAMP);
      
      SET @companyId = (SELECT SCOPE_IDENTITY());
      
      Insert into portal.Location (companyId, locationName, isDeleted, dateUpdated)
      values (@companyId, 'Main site', 0, CURRENT_TIMESTAMP);
    END
  else
    BEGIN
      UPDATE portal.Company
      SET 
          companyName = @companyName,
          email = @email,
          registrationNumber = @registrationNumber,
          phone = @phone,
          address = @address,
          industryType = @industryType,
          industryTypeOther = @industryTypeOther,
          website = @website,
          currency = @currency,
          contactName = @contactName, 
          jobTitle = @jobTitle,
          status = @status,
          logo = @logo,
          countryId = @countryId, 
          nczCustomerDirectory = @nczCustomerDirectory,
          linkedInPage = @linkedInPage, 
          description = @description,
          locationCnt = @locationCnt,
          companyTaskId = @companyTaskId,
          personTaskId = @personTaskId,
          dateUpdated = CURRENT_TIMESTAMP
      WHERE companyId = @companyId;
    END
  
    if @companyId is Not NULL -- return added/updated company data to frontend to show in grid etc
    BEGIN
      exec portal.spCompany_Get @status = null, @companyId = @companyId;
    END
    --SELECT * FROM portal.Company WHERE companyId = @companyId;
END;
GO


-- ----------------------------
-- procedure structure for spCurrency_GetDDL
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spCurrency_GetDDL]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spCurrency_GetDDL]
GO

CREATE PROCEDURE [portal].[spCurrency_GetDDL]
 
AS
BEGIN

    SET NOCOUNT ON;
  
    SELECT currencyCode, currencyName From Lookups.Currencies;
    
END
GO


-- ----------------------------
-- procedure structure for spSubmissionPublicForm_Save
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spSubmissionPublicForm_Save]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spSubmissionPublicForm_Save]
GO

CREATE PROCEDURE [portal].[spSubmissionPublicForm_Save]
  @dimFormId int,
  @submissionId int
AS
BEGIN
  -- For publically accessible forms, what should be done after NCZ Form submitted.

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
      
    end
--   else if(@dimFormId = 26) -- C & HW, if certSubmission is not added before submit then
--     begin
--       
--     
--     end
  

END
GO


-- ----------------------------
-- procedure structure for spEmissionProfile_Get
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[Emissions].[spEmissionProfile_Get]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [Emissions].[spEmissionProfile_Get]
GO

CREATE PROCEDURE [Emissions].[spEmissionProfile_Get]
  @emissionProfileId int = null
AS
BEGIN
    SET NOCOUNT ON;

    if @emissionProfileId is null 
      begin
        SELECT E.*
        FROM Emissions.EmissionProfile AS E
        WHERE E.active = 1;
      end
    ELSE
      begin
        SELECT E.*
        FROM Emissions.EmissionProfile AS E
        WHERE E.active = 1 OR id = @emissionProfileId;
      end
END
GO