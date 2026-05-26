-- ============================================================
-- Update spSupplier_Get to include owner company name and
-- certification info for suppliers grid display.
-- Date: 2026-05-01
-- ============================================================

CREATE OR ALTER PROCEDURE [portal].[spSupplier_Get]
    @companyId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.supplierId,
        s.companyId,
        s.name,
        s.email,
        s.phone,
        s.companyName,
        s.industry,
        s.spend,
        s.certId,
        c.companyName   AS ownerCompanyName,
        cert.refNumber  AS certRefNumber,
        cert.certYear   AS certYear,
        prg.progName    AS certProgName
    FROM   [portal].[Supplier]      s
    LEFT JOIN [portal].[Company]      c    ON c.companyId = s.companyId
    LEFT JOIN [portal].[Certification] cert ON cert.certId = s.certId
    LEFT JOIN [portal].[Programme]    prg  ON prg.progId  = cert.progId
    WHERE  (@companyId IS NULL OR s.companyId = @companyId)
      AND  ISNULL(s.isDeleted, 0) = 0
    ORDER  BY s.name ASC;
END;
GO

CREATE OR ALTER PROCEDURE portal.spSupplyChainDocument_Get
    @companyId INT = NULL  -- optional
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        sd.displayName,
        d.id AS documentId,
        d.parentEntityType,
        sd.companyId,
        c.companyName,
        c.logo,
        FORMAT(DATEADD(SECOND, d.modifiedDate, '1970-01-01'), 'dd/MM/yyyy HH:mm') AS uploadedDate
    FROM Documents.Document AS d
    INNER JOIN portal.SupplyChainDocuments AS sd 
        ON d.id = sd.documentId 
       AND sd.isDeleted = 0
    LEFT JOIN portal.company AS c 
        ON c.companyId = sd.companyId
    WHERE d.activeTo IS NULL
      AND (@companyId IS NULL OR sd.companyId = @companyId)
    ORDER BY d.modifiedDate desc;
END;
GO

-- ============================================================
-- merged from: 2026.05.01_rb_webinar.sql
-- ============================================================


-- ============================================================
-- Webinar invitation HTML content + ICS organizer improvements
-- Date: 2026-05-01
-- ============================================================

-- 1. Add invitationHtml column to Webinars
-- ─────────────────────────────────────────────────────────────
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE  object_id = OBJECT_ID(N'[portal].[Webinars]')
      AND  name = 'invitationHtml'
)
BEGIN
    ALTER TABLE [portal].[Webinars]
    ADD [invitationHtml] NVARCHAR(MAX) NULL;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 2. spWebinar_Save — add @invitationHtml parameter
-- ─────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE [portal].[spWebinar_Save]
    @webinarId            INT            = NULL,
    @title                NVARCHAR(500)  = NULL,
    @description          NVARCHAR(MAX)  = NULL,
    @organizerUserId      INT            = NULL,
    @companyId            INT            = NULL,
    @tokenKey             NVARCHAR(200)  = NULL,
    @postWebinarFormToken NVARCHAR(200)  = NULL,
    @isActive             BIT            = NULL,
    @timezone             NVARCHAR(64)   = NULL,
    @invitationHtml       NVARCHAR(MAX)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @webinarId IS NULL OR @webinarId = 0
    BEGIN
        INSERT INTO [portal].[Webinars]
            ([title], [description], [organizerUserId], [companyId], [tokenKey],
             [postWebinarFormToken], [isActive], [timezone], [invitationHtml],
             [createdAt], [updatedAt])
        VALUES
            (@title, @description, @organizerUserId, @companyId, @tokenKey,
             @postWebinarFormToken, COALESCE(@isActive, 1), COALESCE(@timezone, 'UTC'),
             @invitationHtml, GETUTCDATE(), GETUTCDATE());
        SET @webinarId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE [portal].[Webinars]
        SET
            [title]                = COALESCE(@title,                [title]),
            [description]          = COALESCE(@description,          [description]),
            [organizerUserId]      = COALESCE(@organizerUserId,      [organizerUserId]),
            [companyId]            = COALESCE(@companyId,            [companyId]),
            [tokenKey]             = COALESCE(@tokenKey,             [tokenKey]),
            [postWebinarFormToken] = CASE WHEN @postWebinarFormToken IS NOT NULL
                                         THEN @postWebinarFormToken
                                         ELSE [postWebinarFormToken] END,
            [isActive]             = COALESCE(@isActive,             [isActive]),
            [timezone]             = COALESCE(@timezone,             [timezone]),
            [invitationHtml]       = CASE WHEN @invitationHtml IS NOT NULL
                                         THEN @invitationHtml
                                         ELSE [invitationHtml] END,
            [updatedAt]            = GETUTCDATE()
        WHERE [webinarId] = @webinarId;
    END;

    SELECT w.*,
           c.companyName,
           u.email    AS organizerEmail,
           u.fullName AS organizerName,
           (SELECT COUNT(*) FROM [portal].[WebinarBookings] wb WHERE wb.webinarId = w.webinarId) AS totalBookings,
           (SELECT COUNT(*) FROM [portal].[WebinarSlots]    ws WHERE ws.webinarId = w.webinarId) AS slotCount
    FROM   [portal].[Webinars] w
    LEFT JOIN [portal].[Company] c ON c.companyId    = w.companyId
    LEFT JOIN [portal].[Users]   u ON u.userId       = w.organizerUserId
    WHERE  w.webinarId = @webinarId;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 3. spWebinar_Get — include invitationHtml in output
-- ─────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE [portal].[spWebinar_Get]
    @webinarId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT w.*,
           c.companyName,
           u.email    AS organizerEmail,
           u.fullName AS organizerName,
           (SELECT COUNT(*) FROM [portal].[WebinarBookings] wb  WHERE wb.webinarId = w.webinarId) AS totalBookings,
           (SELECT COUNT(*) FROM [portal].[WebinarSlots]    ws  WHERE ws.webinarId = w.webinarId) AS slotCount,
           (SELECT ISNULL(SUM(ws3.capacity), 0)
            FROM   [portal].[WebinarSlots] ws3 WHERE ws3.webinarId = w.webinarId)                 AS totalCapacity,
           (
               SELECT STRING_AGG(CONVERT(NVARCHAR(19), ws2.slotDateTime, 126), ',')
               WITHIN GROUP (ORDER BY ws2.slotDateTime)
               FROM [portal].[WebinarSlots] ws2
               WHERE ws2.webinarId = w.webinarId
           ) AS slotDates
    FROM   [portal].[Webinars] w
    LEFT JOIN [portal].[Company] c ON c.companyId = w.companyId
    LEFT JOIN [portal].[Users]   u ON u.userId    = w.organizerUserId
    WHERE  (@webinarId IS NULL OR w.webinarId = @webinarId)
      AND  w.isActive = 1
    ORDER BY w.createdAt DESC;

    IF @webinarId IS NOT NULL
    BEGIN
        SELECT s.*,
               (s.capacity - s.bookedCount) AS remaining,
               CASE WHEN s.bookedCount >= s.capacity THEN 1 ELSE 0 END AS isFull
        FROM   [portal].[WebinarSlots] s
        WHERE  s.webinarId = @webinarId
        ORDER  BY s.slotDateTime ASC;
    END;
END;
GO

