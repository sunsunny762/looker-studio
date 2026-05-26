/*
 Navicat Premium Data Transfer

 Source Server         : NCZ [Dev]
 Source Server Type    : SQL Server
 Source Server Version : 12009051 (12.00.9051)
 Source Host           : ncz.database.windows.net:1433
 Source Catalog        : nczdev
 Source Schema         : portal

 Target Server Type    : SQL Server
 Target Server Version : 12009051 (12.00.9051)
 File Encoding         : 65001

 Date: 03/03/2026 16:53:19
*/

ALTER TABLE [portal].[NCZDirectory] ADD [isSupplier] bit NULL
GO

EXEC sp_addextendedproperty
'MS_Description', N'Supplier is non-customer of ncz',
'SCHEMA', N'portal',
'TABLE', N'NCZDirectory',
'COLUMN', N'isSupplier'

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
      
    end

END
GO


-- ----------------------------
-- procedure structure for spNCZDirectory_Get
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spNCZDirectory_Get]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spNCZDirectory_Get]
GO

CREATE PROCEDURE [portal].[spNCZDirectory_Get]
  @dirItemId INT = NULL,
  @showAll BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- Case 1: companyId + certId are valid
    SELECT DISTINCT
        ND.dirItemId,
        Crt.refNumber AS customerReference,
        Crt.certificationTaskId AS certTaskId,
        ND.isVisible,
        ND.isArchive,
        C.companyName,
        ND.salesName, ND.salesEmail, ND.salesPhone,
        ND.esgName, ND.esgEmail, ND.esgPhone,
        ND.emissionOffset,
        CASE C.industryType 
             WHEN 30 THEN C.industryTypeOther 
             ELSE DI.itemName 
        END AS industryType,
        ND.companyDescription, ND.offersDiscounts,
        ND.co2PerRevenue,
        ND.companyId,
        Nd.certId,

        -- Short Offers
        CASE 
            WHEN LEN(ND.offersDiscounts) - LEN(REPLACE(ND.offersDiscounts, ' ', '')) + 1 > 5
                THEN LEFT(ND.offersDiscounts, 
                          CHARINDEX(' ', ND.offersDiscounts + ' ', 
                          CHARINDEX(' ', ND.offersDiscounts + ' ', 
                          CHARINDEX(' ', ND.offersDiscounts + ' ', 
                          CHARINDEX(' ', ND.offersDiscounts + ' ', 
                          CHARINDEX(' ', ND.offersDiscounts + ' ') + 1) + 1) + 1) + 1)) 
                     + '...'
                ELSE ND.offersDiscounts
        END AS shortOffersDiscounts,

        -- Website & Social Links
        CASE WHEN C.website IS NULL OR C.website NOT LIKE '%[.][a-z]%' THEN ''
             WHEN C.website LIKE 'http%' THEN C.website
             ELSE 'http://' + C.website END AS website,

        CASE 
            WHEN (C.linkedInPage IS NULL OR C.linkedInPage NOT LIKE '%linkedin.%') 
                 AND (ND.linkedInPage IS NULL OR ND.linkedInPage NOT LIKE '%linkedin.%') THEN ''
            WHEN C.linkedInPage IS NULL OR C.linkedInPage NOT LIKE '%linkedin.%' THEN
                CASE 
                    WHEN ND.linkedInPage LIKE 'http%' THEN ND.linkedInPage
                    ELSE 'https://' + ND.linkedInPage
                END
            WHEN C.linkedInPage LIKE 'http%' THEN C.linkedInPage
            ELSE 'https://' + C.linkedInPage
        END AS linkedInPage,

        CASE WHEN ND.facebookPage IS NULL OR ND.facebookPage NOT LIKE '%facebook.%' THEN ''
             WHEN ND.facebookPage LIKE 'http%' THEN ND.facebookPage
             ELSE 'https://' + ND.facebookPage END AS facebookPage,

        CASE WHEN ND.instagramPage IS NULL OR ND.instagramPage NOT LIKE '%instagram.%' THEN ''
             WHEN ND.instagramPage LIKE 'http%' THEN ND.instagramPage
             ELSE 'https://' + ND.instagramPage END AS instagramPage,

        CASE WHEN C.logo LIKE 'https://app.neutralcarbonzone.com/uploads/%' 
                  THEN C.logo + '?apiKey=964f4219f34a79448399110d86da47f4'
             ELSE C.logo
        END AS logo,
        case when nd.isSupplier=1 then 'Verified Supplier' else p.progName end AS product,
        nd.isSupplier
        
    FROM portal.NCZDirectory AS ND
         INNER JOIN portal.Company AS C ON ND.companyId = C.companyId
         LEFT JOIN portal.DropdownItems AS DI ON C.industryType = DI.itemId
         INNER JOIN portal.Certification AS Crt ON ND.certId = Crt.certId
         LEFT JOIN portal.Programme AS P ON Crt.progId = P.progId
        
    WHERE (ND.companyId IS NOT NULL AND ND.companyId <> 0)
      AND (ND.certId IS NOT NULL AND ND.certId <> 0)
      AND (
            ( @dirItemId IS NOT NULL AND ND.dirItemId = @dirItemId )
            OR
            ( @dirItemId IS NULL AND ( @showAll = 1 OR ND.isVisible = 1 ))
          )

    UNION ALL

    -- Case 2: fallback when companyId / certId invalid
    SELECT DISTINCT
        ND.dirItemId,
        ND.customerReference,
        ND.certTaskId,
        ND.isVisible,
        ND.isArchive,
        ND.companyName,
        ND.salesName, ND.salesEmail, ND.salesPhone,
        ND.esgName, ND.esgEmail, ND.esgPhone,
        ND.emissionOffset,
        ND.industryType,
        ND.companyDescription, ND.offersDiscounts,
        ND.co2PerRevenue,
        ND.companyId,
        Nd.certId,

        CASE 
            WHEN LEN(ND.offersDiscounts) - LEN(REPLACE(ND.offersDiscounts, ' ', '')) + 1 > 5
                THEN LEFT(ND.offersDiscounts, 
                          CHARINDEX(' ', ND.offersDiscounts + ' ', 
                          CHARINDEX(' ', ND.offersDiscounts + ' ', 
                          CHARINDEX(' ', ND.offersDiscounts + ' ', 
                          CHARINDEX(' ', ND.offersDiscounts + ' ', 
                          CHARINDEX(' ', ND.offersDiscounts + ' ') + 1) + 1) + 1) + 1)) 
                     + '...'
              ELSE ND.offersDiscounts
        END AS shortOffersDiscounts,

        CASE WHEN ND.website IS NULL OR ND.website NOT LIKE '%[.][a-z]%' THEN ''
             WHEN ND.website LIKE 'http%' THEN ND.website
             ELSE 'http://' + ND.website END AS website,

        CASE WHEN ND.linkedInPage IS NULL OR ND.linkedInPage NOT LIKE '%linkedin.%' THEN ''
             WHEN ND.linkedInPage LIKE 'http%' THEN ND.linkedInPage
             ELSE 'https://' + ND.linkedInPage END AS linkedInPage,

        CASE WHEN ND.facebookPage IS NULL OR ND.facebookPage NOT LIKE '%facebook.%' THEN ''
             WHEN ND.facebookPage LIKE 'http%' THEN ND.facebookPage
             ELSE 'https://' + ND.facebookPage END AS facebookPage,

        CASE WHEN ND.instagramPage IS NULL OR ND.instagramPage NOT LIKE '%instagram.%' THEN ''
             WHEN ND.instagramPage LIKE 'http%' THEN ND.instagramPage
             ELSE 'https://' + ND.instagramPage END AS instagramPage,

        CASE WHEN ND.logo LIKE 'https://app.neutralcarbonzone.com/uploads/%' 
                  THEN ND.logo + '?apiKey=964f4219f34a79448399110d86da47f4'
             ELSE ND.logo
        END AS logo,
        case when nd.isSupplier=1 then 'Verified Supplier' else CF.[value] end AS product,
        nd.isSupplier

    FROM portal.NCZDirectory AS ND
         LEFT JOIN clickup.CustomField AS CF 
                ON (CF.taskId = ND.certTaskId AND CF.name = 'Product' AND CF.value IS NOT NULL)
    WHERE (ND.companyId IS NULL OR ND.companyId = 0
           OR ND.certId IS NULL OR ND.certId = 0)
      AND (
            ( @dirItemId IS NOT NULL AND ND.dirItemId = @dirItemId )
            OR
            ( @dirItemId IS NULL AND ( @showAll = 1 OR ND.isVisible = 1 ))
          )

    ORDER BY isVisible, companyName;
END
GO


-- ----------------------------
-- procedure structure for spNCZDirectorySupplier_Save
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spNCZDirectorySupplier_Save]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spNCZDirectorySupplier_Save]
GO

CREATE PROCEDURE [portal].[spNCZDirectorySupplier_Save]
    @submissionId int
AS
BEGIN
    SET NOCOUNT ON;

    IF Not EXISTS (SELECT 1 FROM portal.NCZDirectory WHERE submissionId = CAST(@submissionId AS NVARCHAR(20)))
    BEGIN
        -- INSERT
        INSERT INTO portal.NCZDirectory (
            submissionId,
            companyName,
            salesName,
            salesEmail,
            salesPhone,
            esgName,
            esgEmail,
            esgPhone,
            website,
            linkedinPage,
            facebookPage,
            instagramPage,
            logo,
            emissionOffset,
            industryType,
            companyDescription,
            offersDiscounts,
            isSupplier
        )
        SELECT
            submissionId,
            MAX(CASE WHEN questionId = 945 THEN responseData END), -- AS companyName,
            MAX(CASE WHEN questionId = 944 THEN responseData END), --  AS salesName,
            MAX(CASE WHEN questionId = 946 THEN responseData END), --  AS salesEmail,
            MAX(CASE WHEN questionId = 947 THEN responseData END), --  AS salesPhone,
            MAX(CASE WHEN questionId = 948 THEN responseData END), --  AS esgName,
            MAX(CASE WHEN questionId = 950 THEN responseData END), --  AS esgEmail,
            MAX(CASE WHEN questionId = 951 THEN responseData END), --  AS esgPhone,
            MAX(CASE WHEN questionId = 952 THEN responseData END), --  AS website,
            MAX(CASE WHEN questionId = 953 THEN responseData END), --  AS linkedinPage,
            MAX(CASE WHEN questionId = 954 THEN responseData END), --  AS facebookPage,
            MAX(CASE WHEN questionId = 955 THEN responseData END), --  AS instagramPage,
            MAX(CASE WHEN questionId = 956 AND ISJSON(responseData) = 1 THEN JSON_VALUE(responseData, '$[0]') END), --  AS logo,
            MAX(CASE WHEN questionId = 959 THEN responseData END), --  AS emissionOffset,
            MAX(CASE WHEN questionId = 960 THEN responseData END), --  AS industryType,
            MAX(CASE WHEN questionId = 961 THEN responseData END), --  AS companyDescription,
            MAX(CASE WHEN questionId = 962 THEN responseData END), --  AS offersDiscounts,
            MAX(CASE WHEN questionId = 958 AND responseData = 'verified_supplier' Then 1 END) --  AS isSupplier
        FROM portal.FormSubmissionResponses where submissionId = @submissionId
        GROUP BY submissionId;
        
    END

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
  Select 1;

END
GO

