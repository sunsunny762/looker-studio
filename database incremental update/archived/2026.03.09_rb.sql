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

 Date: 09/03/2026 16:02:30
*/

	ALTER TABLE [portal].[Location] ADD [countryId] int NULL
	GO
	ALTER TABLE [portal].[Location] ADD [currency] nvarchar(3) NULL
	GO
	ALTER TABLE [portal].[Location] ADD [isPrimary] bit NULL
	GO
	ALTER TABLE [portal].[Location] ADD [logo] nvarchar(200) NULL
	GO
	
  -- Set Primary location for companies
  UPDATE l
  SET l.isPrimary = 1
  FROM portal.Location l
  INNER JOIN (
      SELECT companyId, MIN(locationId) AS primarylocationId
      FROM portal.Location
      WHERE isDeleted = 0
      GROUP BY companyId
  ) x 
      ON l.locationId = x.primarylocationId;

	-- ApplicationFeature
	SET IDENTITY_INSERT [portal].[ApplicationFeature] ON;

	INSERT INTO [portal].[ApplicationFeature]
	([id], [applicationId], [name], [description], [displayName])
	VALUES
	(15, 1, N'company-profile', NULL, N'Company Profile');

	SET IDENTITY_INSERT [portal].[ApplicationFeature] OFF;


	-- ApplicationFeatureOption
	SET IDENTITY_INSERT [portal].[ApplicationFeatureOption] ON;

	INSERT INTO [portal].[ApplicationFeatureOption]
	([id], [applicationFeatureId], [name], [description], [displayName])
	VALUES
	(41, 15, N'availableFromMainMenu', N'Company Profile', N'Company Profile');

	SET IDENTITY_INSERT [portal].[ApplicationFeatureOption] OFF;


	-- ApplicationRoleOption
	SET IDENTITY_INSERT [portal].[ApplicationRoleOption] ON;

	INSERT INTO [portal].[ApplicationRoleOption]
	([id], [applicationRoleId], [applicationFeatureOptionId], [available], [assignable])
	VALUES
	(82, 2, 41, '1', '0');

	SET IDENTITY_INSERT [portal].[ApplicationRoleOption] OFF;
	
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
    @description nvarchar(300) = null,
    @linkedInPage nvarchar(100) = null,
    @locationCnt INT = 1,
    @companyTaskId NVARCHAR(15) = null,
    @personTaskId NVARCHAR(15) = null
AS
BEGIN
  SET NOCOUNT ON;
  
  if @companyId is NULL
    BEGIN
      INSERT INTO portal.Company 
      (companyName, email, registrationNumber, phone, address, industryType, industryTypeOther, website, 
       contactName, jobTitle, status, linkedInPage, description, locationCnt, companyTaskId, personTaskId, dateCreated)
      VALUES 
      (@companyName, @email, @registrationNumber, @phone, @address, @industryType, @industryTypeOther, @website, 
       @contactName, @jobTitle, @status, @linkedInPage, @description, @locationCnt, @companyTaskId, @personTaskId, CURRENT_TIMESTAMP);
      
      SET @companyId = (SELECT SCOPE_IDENTITY());
      
      Insert into portal.Location (companyId, locationName, isPrimary, isDeleted, dateUpdated)
      values (@companyId, 'Main site', 0, 1, CURRENT_TIMESTAMP);
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
          contactName = @contactName, 
          jobTitle = @jobTitle,
          status = @status,
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
-- procedure structure for spLocation_Get
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spLocation_Get]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spLocation_Get]
GO

CREATE PROCEDURE [portal].[spLocation_Get]
  @companyId int = null,
  @locationId int = null
AS
BEGIN
  SET NOCOUNT ON;
  
  if @companyId is null 
    BEGIN
      SELECT L.*, C.companyName, C.locationCnt, cntr.countryName, l.locationName as displayName
      From portal.Location as L 
      INNER JOIN portal.Company as C on (C.companyId = L.companyId)
      LEFT JOIN Lookups.Countries as cntr on (L.countryId = cntr.countryId)
      Where L.locationId = @locationId;
    END
  ELSE
    BEGIN
      SELECT L.locationId, L.companyId, L.locationName, 
            CONCAT(L.locationName, '', ' (locId: ', CAST(L.locationId AS nvarchar(20)), ')') as displayName, 
            C.companyName, L.isPrimary, L.currency, L.countryId, cntr.countryName
        --L.*, C.companyName
      From portal.Location as L 
      INNER JOIN portal.Company as C on (C.companyId = L.companyId)
      LEFT JOIN Lookups.Countries as cntr on (L.countryId = cntr.countryId)
      Where L.isDeleted = 0 and L.companyId = @companyId;
    END

END
GO


-- ----------------------------
-- procedure structure for spLocation_Save
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spLocation_Save]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spLocation_Save]
GO

CREATE PROCEDURE [portal].[spLocation_Save]
    @locationId int,
    @locationName NVARCHAR(50),
    @companyId int,
    @countryId int = null,
    @currency nvarchar(3) = null,
    @logo nvarchar(200) = null,
    @isPrimary bit = 0
AS
BEGIN
  SET NOCOUNT ON;
  
  if @locationId is NULL
    BEGIN
      INSERT INTO portal.Location 
      (locationName, companyId, countryId, currency, logo, isPrimary, dateUpdated)
      VALUES 
      (@locationName, @companyId, @countryId, @currency, @logo, @isPrimary, CURRENT_TIMESTAMP);
      
      SET @locationId = (SELECT SCOPE_IDENTITY());
    END
  else
    BEGIN
      UPDATE portal.Location
      SET 
          locationName = @locationName,
          countryId = @countryId,
          currency = @currency,
          logo = @logo,
          dateUpdated = CURRENT_TIMESTAMP
      WHERE locationId = @locationId;
      
      if exists (select * from portal.Location where isPrimary=1 and logo is not null and locationId = @locationId)
      BEGIN
        -- Set primary location logo as Company logo
        UPDATE c
          SET c.logo = l.logo
        FROM portal.Company c
        INNER JOIN portal.Location l ON l.companyId = c.companyId
        WHERE l.locationId = @locationId;
      END
    END
  
    if @locationId is Not NULL -- return added/updated location data to frontend to show in grid etc
    BEGIN
      exec portal.spLocation_Get null, @locationId;
    END

END;
GO


-- ----------------------------
-- procedure structure for spSubmission_GetByProgFormId
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spSubmission_GetByProgFormId]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spSubmission_GetByProgFormId]
GO

CREATE PROCEDURE [portal].[spSubmission_GetByProgFormId]
  @certId int,
  @progFormId int,
  @locationId int = null
AS
BEGIN
  -- For Tiles
    SET NOCOUNT ON;
  
    if (@progFormId IN (201,301,401)) -- Company Profile
      BEGIN
        Select cfs.certsubmissionId, cfs.submissionId, df.dataSourceId, 
               FORMAT(cfs.dateSubmitted, 'dd/MM/yyyy') as dateSubmitted, 
               case when cfs.userId=0 then cfs.notes else u.fullName end as submittedBy,
               case when cfs.userId=0 then '' else cfs.notes end as notes,
               case when cfs.isDraft = 1 then 'Draft' else (case cfs.isProcessed when 1 then 'Processed' else 'Submitted' end) end as formStatus,
               l.locationName, pf.displayName as formName,
               0 as isCHW, 1 as isCMP, cfs.isMBD, cfs.isDraft, cfs.isProcessed,
               CASE WHEN (pf.progFormId IN (201,301,401)) THEN pl.locationName else null end as parentCMPLocationName
        From portal.CertFormSubmissions as cfs 
          INNER JOIN portal.Certification as c on (c.certId = cfs.certId)
          INNER JOIN portal.Programme as p on (c.progId = p.progId)
          INNER JOIN portal.ProgrammeForms as pf on (p.progId = pf.progId and pf.dimFormId = cfs.dimFormId)
          INNER JOIN Dimension.Form as df on (pf.dimFormId = df.id)
          INNER JOIN portal.Location as L on (L.locationId = cfs.locationId)
          LEFT JOIN portal.Users as u on (u.userId = cfs.userId)
          LEFT JOIN portal.CertFormSubmissions as pcfs on cfs.parentCertsubmissionId = pcfs.certsubmissionId
          LEFT JOIN portal.Location as pl on pcfs.locationId = pl.locationId
        Where cfs.certId = @certId and pf.progFormId = @progFormId and (@locationId IS NULL OR cfs.locationId IN (@locationId, 0))
              and ((df.dataSourceId = 1 AND cfs.isDraft = 0) OR df.dataSourceId <> 1) -- Hide pending/draft for Jotform
        ORDER BY cfs.dateSubmitted desc;
      END
    else -- Other than Company Profile
      BEGIN
        Select cfs.certsubmissionId, cfs.submissionId, df.dataSourceId, 
               FORMAT(cfs.dateSubmitted, 'dd/MM/yyyy') as dateSubmitted, 
               case when cfs.userId=0 then cfs.notes else u.fullName end as submittedBy,
               case when cfs.userId=0 then '' else cfs.notes end as notes,
               case when cfs.isDraft = 1 then 'Draft' else (case cfs.isProcessed when 1 then 'Processed' else 'Submitted' end) end as formStatus,
               l.locationName, pf.displayName as formName,
               case when pf.progFormId IN (209,309,409) then 1 else 0 end as isCHW, 0 as isCMP, cfs.isMBD, cfs.isDraft, cfs.isProcessed,
               null as parentCMPLocationName
        From portal.CertFormSubmissions as cfs 
          INNER JOIN portal.Certification as c on (c.certId = cfs.certId)
          INNER JOIN portal.Programme as p on (c.progId = p.progId)
          INNER JOIN portal.ProgrammeForms as pf on (p.progId = pf.progId and pf.dimFormId = cfs.dimFormId)
          INNER JOIN Dimension.Form as df on (pf.dimFormId = df.id)
          INNER JOIN portal.Location as L on (L.locationId = cfs.locationId)
          LEFT JOIN portal.Users as u on (u.userId = cfs.userId)
        Where cfs.certId = @certId and pf.progFormId = @progFormId and (@locationId IS NULL OR cfs.locationId IN (@locationId, 0))
              and ((df.dataSourceId = 1 AND cfs.isDraft = 0) OR df.dataSourceId <> 1) -- Hide pending/draft for Jotform
        ORDER BY cfs.dateSubmitted desc;
      END
END
GO


-- ----------------------------
-- function structure for fnFuelPrices_AmountToLiters
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[Emissions].[fnFuelPrices_AmountToLiters]') AND type IN ('FN', 'FS', 'FT', 'IF', 'TF'))
	DROP FUNCTION [Emissions].[fnFuelPrices_AmountToLiters]
GO

CREATE FUNCTION [Emissions].[fnFuelPrices_AmountToLiters]
(
    @fuelType NVARCHAR(10),        -- 'PETROL' or 'DIESEL'
    @amount DECIMAL(10, 2),        -- amount in local currency
    @country NVARCHAR(50)
)
RETURNS DECIMAL(10, 4)
AS
BEGIN
    DECLARE @avgPrice DECIMAL(10, 4);
    DECLARE @latestWeekDate DATETIME2(7);

    -- Step 1: Get latest available week for the country
    SELECT @latestWeekDate = MAX(weekDate)
    FROM [Emissions].[FuelPrices]
    WHERE country = @country;

    -- Step 2: Compute 52-week average price based on fuel type
    IF UPPER(@fuelType) = 'PETROL'
    BEGIN
        SELECT @avgPrice = AVG(petrolPrice)
        FROM [Emissions].[FuelPrices]
        WHERE country = @country
          AND weekDate >= DATEADD(WEEK, -52, @latestWeekDate);
    END
    ELSE IF UPPER(@fuelType) = 'DIESEL'
    BEGIN
        SELECT @avgPrice = AVG(dieselPrice)
        FROM [Emissions].[FuelPrices]
        WHERE country = @country
          AND weekDate >= DATEADD(WEEK, -52, @latestWeekDate);
    END
    ELSE
    BEGIN
        RETURN NULL; -- Invalid fuel type
    END

    -- Step 3: Convert pence to pounds if UK
    IF UPPER(@country) = 'UNITED KINGDOM'
    BEGIN
        SET @avgPrice = @avgPrice / 100;
    END

    -- Step 4: Calculate and return litres
    RETURN CASE 
        WHEN @avgPrice > 0 THEN ROUND(@amount / @avgPrice, 4)
        ELSE NULL 
    END;
END;
GO



-- ----------------------------
-- procedure structure for spSubmission_SelectToProcess
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spSubmission_SelectToProcess]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spSubmission_SelectToProcess]
GO

CREATE PROCEDURE [portal].[spSubmission_SelectToProcess]
	@max int = 500,
	@dataSourceId int = 2 -- NCZ Form
AS
BEGIN
	SET NOCOUNT ON;
  SELECT TOP (@max) -- Certification Form submissions
						cfs.certsubmissionId, fs.submissionId, nf.formId, nf.formName, cfs.dimFormId, df.categoryId,
						5 as entityTypeId, -- Portal Customer
            cert.progId, cert.certId, c.companyId, cert.certificationTaskId as certTaskId, c.companyName,
            cntr.countryName as country, l.currency as currency
	FROM portal.CertFormSubmissions cfs
  INNER JOIN portal.FormSubmissions as fs ON cfs.submissionId = fs.submissionId
	INNER JOIN portal.Forms nf on nf.formId = fs.formId
	INNER JOIN Dimension.Form df on df.id = cfs.dimFormId AND df.dataSourceId = @dataSourceId and df.categoryId in (1,4,5)
  INNER JOIN portal.Certification as cert on (cert.certId = cfs.certId)
  INNER JOIN portal.Company as c on (c.companyId = cert.companyId)
  INNER JOIN portal.Location as l on (c.companyId = l.companyId and l.isDeleted = 0)
  INNER JOIN Lookups.Countries as cntr on (l.countryId = cntr.countryId)
	WHERE (l.countryId is not null or l.currency is not null) -- country and currency needs to have
        and cfs.isProcessed = 0 And cfs.isDraft = 0 AND nf.isActive = 1 And cfs.parentCertsubmissionId is NULL
        and cfs.dateSubmitted >= DATEADD(DAY, -7, GETDATE()) -- For LIVE DB
        
  UNION -- Blue Award submissions
    SELECT  cfs.certsubmissionId, fs.submissionId, nf.formId, nf.formName, cfs.dimFormId, df.categoryId,
            5 as entityTypeId, -- Portal Customer
            1 as progId, 0 as certId, 0 as companyId, '' as certTaskId,
            fsr.companyName,
            JSON_VALUE(fsr.countryJson, '$.value') AS country,
            JSON_VALUE(fsr.currencyJson, '$.value') AS currency
      FROM portal.CertFormSubmissions cfs
      INNER JOIN portal.FormSubmissions as fs ON cfs.submissionId = fs.submissionId
      INNER JOIN portal.Forms nf on nf.formId = fs.formId
      INNER JOIN Dimension.Form df on df.id = cfs.dimFormId and df.categoryId = 4 -- Blue
      CROSS APPLY
      (
          SELECT
              MAX(CASE WHEN questionId = 817 THEN responseData END) AS companyName,
              MAX(CASE WHEN questionId = 822 THEN responseData END) AS countryJson,
              MAX(CASE WHEN questionId = 834 THEN responseData END) AS currencyJson
          FROM portal.FormSubmissionResponses tfsr
          WHERE tfsr.submissionId = fs.submissionId
      ) fsr
      WHERE cfs.dimFormId = 29
            and cfs.isProcessed = 0 AND nf.isActive = 1 
            and cfs.dateSubmitted >= DATEADD(DAY, -7, GETDATE());
       
END
GO