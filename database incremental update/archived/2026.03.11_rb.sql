-- Silver, About you company form, Head count questions removed
	UPDATE [portal].[FormQuestions] SET  [isActive] = 0 WHERE [questionId] in (868, 869);
	UPDATE [portal].[FormSections] SET  [isActive] = 0 WHERE [sectionId] = 200;

-- Gold & Platinum, removed About your company form
	UPDATE [portal].[ProgrammeForms] SET isActive = 0 where [progId] in (3, 4) and [dimFormId] = 30;

-- ============================================================
-- SP: spCertCHWTokens_Get
--   Returns location tokens for C&HW links, now including
--   countryName, currency (from Location/Countries) and
--   per-location headCount & revenue (from CertificationHeadCount).
-- ============================================================
IF EXISTS (
    SELECT * FROM sys.all_objects
    WHERE object_id = OBJECT_ID(N'[portal].[spCertCHWTokens_Get]')
    AND type IN ('P', 'PC', 'RF', 'X')
)
    DROP PROCEDURE [portal].[spCertCHWTokens_Get]
GO

CREATE PROCEDURE [portal].[spCertCHWTokens_Get]
  @certId int
AS
BEGIN

  -- if token not exists for certId, locationId for tokenType='Form' then add those
  INSERT INTO [portal].[Tokens] (certId, locationId, dimFormId, activeTo, isActive, tokenType, properties)
  Select cert.certId, l.locationId, 26, null, 1, 'form', null
  from portal.Certification as cert 
  INNER JOIN portal.Location as l on (cert.companyId = l.companyId and l.isDeleted = 0)
  LEFT JOIN portal.Tokens as t on (t.locationId = l.locationId and t.certId = cert.certId 
                                    and t.isActive = 1 and (t.activeTo IS NULL OR t.activeTo >= GETDATE())
                                    and t.tokenType = 'form' and t.dimFormId = 26
                                   )
  where t.tokenKey is null and cert.certId = @certId;
  
  Select l.locationId, l.locationName, t.tokenKey,
         cntr.countryName, l.currency,
         hc.headCount, hc.revenue
  from portal.Certification as cert 
  INNER JOIN portal.Location as l on (cert.companyId = l.companyId and l.isDeleted = 0)
  INNER JOIN portal.Tokens as t on (t.locationId = l.locationId and t.certId = cert.certId 
                                    and t.isActive = 1 and (t.activeTo IS NULL OR t.activeTo >= GETDATE())
                                    and t.tokenType = 'form' and t.dimFormId = 26
                                   )
  LEFT JOIN Lookups.Countries as cntr on (l.countryId = cntr.countryId)
  LEFT JOIN portal.CertificationHeadCount as hc on (hc.certId = cert.certId and hc.locationId = l.locationId)
  where cert.certId = @certId
  ORDER BY l.locationName;

END
GO


-- ============================================================
-- SP: spCertification_Save
--   Adds optional @headCount parameter so the certification
--   add/edit dialog can persist headcount alongside the cert.
-- ============================================================
IF EXISTS (
    SELECT * FROM sys.all_objects
    WHERE object_id = OBJECT_ID(N'[portal].[spCertification_Save]')
    AND type IN ('P', 'PC', 'RF', 'X')
)
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
    @headCount INT = NULL,
    @userId INT = NULL
AS
BEGIN

  SET NOCOUNT ON;

  IF @certId IS NULL
    BEGIN
        INSERT INTO portal.certification (
            companyId, progId, startDate, endDate, status, refNumber, emissionProfileId, revenue,
            description, certificationTaskId, certYear, isDeleted, headCount
        )
        VALUES (
            @companyId, @progId, @startDate, DATEADD(DAY, -1, DATEADD(YEAR, 1, @startDate)), @status, @refNumber, @emissionProfileId, @revenue,
            @description, @certificationTaskId, YEAR(@startDate), 0, @headCount
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
            certYear = YEAR(@startDate),
            headCount = ISNULL(@headCount, headCount)
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
