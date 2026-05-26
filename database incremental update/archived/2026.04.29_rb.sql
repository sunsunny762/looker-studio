-- ============================================================
-- Add optional @slotId filter to spWebinarBooking_Get
-- Allows fetching all confirmed bookings for a specific slot.
-- Date: 2026-04-29
-- ============================================================

CREATE OR ALTER PROCEDURE [portal].[spWebinarBooking_Get]
    @webinarId INT = NULL,
    @bookingId INT = NULL,
    @slotId    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT b.*,
           s.slotDateTime,
           s.capacity,
           s.bookedCount,
           s.meetingLink
    FROM   [portal].[WebinarBookings] b
    JOIN   [portal].[WebinarSlots]    s ON s.slotId = b.slotId
    WHERE  (@webinarId IS NULL OR b.webinarId = @webinarId)
      AND  (@bookingId IS NULL OR b.bookingId = @bookingId)
      AND  (@slotId    IS NULL OR b.slotId    = @slotId)
      AND  b.status = 'confirmed'
    ORDER  BY s.slotDateTime ASC, b.createdAt ASC;
END;
GO


-- ============================================================
-- merged from: 2026.04.29_rb_webinar_tz_duration.sql
-- ============================================================


-- ============================================================
-- Webinar: Add timezone to Webinars, durationMinutes to
-- WebinarSlots, and update all affected stored procedures.
-- All slot datetimes are now stored as UTC. The timezone field
-- (IANA name, e.g. "Europe/London") is stored on the Webinar
-- so organisers can express slots in their chosen timezone.
-- Date: 2026-04-29
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- 1. Add timezone column to Webinars
-- ─────────────────────────────────────────────────────────────

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE  object_id = OBJECT_ID('[portal].[Webinars]') AND name = 'timezone'
)
BEGIN
    ALTER TABLE [portal].[Webinars]
    ADD [timezone] NVARCHAR(64) NOT NULL DEFAULT 'UTC';
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 2. Add durationMinutes column to WebinarSlots
-- ─────────────────────────────────────────────────────────────

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE  object_id = OBJECT_ID('[portal].[WebinarSlots]') AND name = 'durationMinutes'
)
BEGIN
    ALTER TABLE [portal].[WebinarSlots]
    ADD [durationMinutes] INT NOT NULL DEFAULT 45;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 3. spWebinar_Save — accept and persist @timezone
-- ─────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE [portal].[spWebinar_Save]
    @webinarId            INT            = NULL,
    @title                NVARCHAR(500)  = NULL,
    @description          NVARCHAR(MAX)  = NULL,
    @organizerUserId      INT            = NULL,
    @companyId            INT            = NULL,
    @tokenKey             NVARCHAR(200)  = NULL,
    @postWebinarFormToken NVARCHAR(200)  = NULL,
    @isActive             BIT            = 1,
    @timezone             NVARCHAR(64)   = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @webinarId IS NULL OR @webinarId = 0
    BEGIN
        INSERT INTO [portal].[Webinars]
            ([title], [description], [organizerUserId], [companyId], [tokenKey],
             [postWebinarFormToken], [isActive], [timezone], [createdAt], [updatedAt])
        VALUES
            (@title, @description, @organizerUserId, @companyId, @tokenKey,
             @postWebinarFormToken, @isActive, COALESCE(@timezone, 'UTC'), GETUTCDATE(), GETUTCDATE());
        SET @webinarId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE [portal].[Webinars]
        SET
            [title]                = COALESCE(@title, [title]),
            [description]          = COALESCE(@description, [description]),
            [organizerUserId]      = COALESCE(@organizerUserId, [organizerUserId]),
            [companyId]            = COALESCE(@companyId, [companyId]),
            [tokenKey]             = COALESCE(@tokenKey, [tokenKey]),
            [postWebinarFormToken] = CASE WHEN @postWebinarFormToken IS NOT NULL THEN @postWebinarFormToken ELSE [postWebinarFormToken] END,
            [isActive]             = COALESCE(@isActive, [isActive]),
            [timezone]             = COALESCE(@timezone, [timezone]),
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
-- 4. spWebinar_Get — return timezone + organizer + slotDates
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

-- ─────────────────────────────────────────────────────────────
-- 5. spWebinarSlot_Save — accept and persist @durationMinutes
-- ─────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE [portal].[spWebinarSlot_Save]
    @slotId          INT           = NULL,
    @webinarId       INT           = NULL,
    @slotDateTime    DATETIME2     = NULL,
    @capacity        INT           = NULL,
    @meetingLink     NVARCHAR(500) = NULL,
    @durationMinutes INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @slotId IS NULL OR @slotId = 0
    BEGIN
        INSERT INTO [portal].[WebinarSlots]
            ([webinarId], [slotDateTime], [capacity], [meetingLink], [durationMinutes])
        VALUES
            (@webinarId, @slotDateTime, COALESCE(@capacity, 10), @meetingLink, COALESCE(@durationMinutes, 45));
        SET @slotId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE [portal].[WebinarSlots]
        SET    [slotDateTime]    = COALESCE(@slotDateTime,    [slotDateTime]),
               [capacity]        = COALESCE(@capacity,        [capacity]),
               [meetingLink]     = COALESCE(@meetingLink,     [meetingLink]),
               [durationMinutes] = COALESCE(@durationMinutes, [durationMinutes])
        WHERE  [slotId] = @slotId;
    END;

    SELECT s.*, (s.capacity - s.bookedCount) AS remaining
    FROM   [portal].[WebinarSlots] s
    WHERE  s.slotId = @slotId;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 6. spWebinarSlot_Get — return durationMinutes
-- ─────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE [portal].[spWebinarSlot_Get]
    @webinarId INT,
    @activeOnly BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.*,
           (s.capacity - s.bookedCount) AS remaining,
           CASE WHEN s.bookedCount >= s.capacity THEN 1 ELSE 0 END AS isFull
    FROM   [portal].[WebinarSlots] s
    WHERE  s.webinarId = @webinarId
      AND  (@activeOnly = 0 OR s.slotDateTime > GETUTCDATE())
    ORDER  BY s.slotDateTime ASC;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 7. spWebinarBooking_Save — return webinarTimezone
-- ─────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE [portal].[spWebinarBooking_Save]
    @webinarId    INT,
    @slotId       INT,
    @companyId    INT,
    @businessName NVARCHAR(500),
    @contactEmail NVARCHAR(500),
    @tokenKey     NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @capacity INT, @bookedCount INT;
    SELECT @capacity = capacity, @bookedCount = bookedCount
    FROM   [portal].[WebinarSlots]
    WHERE  slotId = @slotId;

    IF @bookedCount >= @capacity
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('Selected time slot is fully booked.', 16, 1);
        RETURN;
    END;

    INSERT INTO [portal].[WebinarBookings]
        ([webinarId], [slotId], [companyId], [businessName], [contactEmail], [status], [tokenKey], [createdAt])
    VALUES
        (@webinarId, @slotId, @companyId, @businessName, @contactEmail, 'confirmed', @tokenKey, GETUTCDATE());

    DECLARE @bookingId INT = SCOPE_IDENTITY();

    UPDATE [portal].[WebinarSlots]
    SET    bookedCount = bookedCount + 1
    WHERE  slotId = @slotId;

    COMMIT TRANSACTION;

    SELECT b.*, s.slotDateTime, s.capacity, s.bookedCount, s.meetingLink, s.durationMinutes,
           w.title       AS webinarTitle,
           w.timezone    AS webinarTimezone,
           u.email       AS organizerEmail,
           u.fullName    AS organizerName
    FROM   [portal].[WebinarBookings] b
    JOIN   [portal].[WebinarSlots]    s ON s.slotId    = b.slotId
    JOIN   [portal].[Webinars]        w ON w.webinarId = b.webinarId
    LEFT JOIN [portal].[Users]        u ON u.userId    = w.organizerUserId
    WHERE  b.bookingId = @bookingId;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 8. spWebinarBooking_GetPendingReminders — return webinarTimezone
-- ─────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE [portal].[spWebinarBooking_GetPendingReminders]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT b.*, s.slotDateTime, s.meetingLink, s.durationMinutes,
           w.title    AS webinarTitle,
           w.timezone AS webinarTimezone,
           u.email    AS organizerEmail,
           u.fullName AS organizerName
    FROM   [portal].[WebinarBookings] b
    JOIN   [portal].[WebinarSlots]    s ON s.slotId    = b.slotId
    JOIN   [portal].[Webinars]        w ON w.webinarId = b.webinarId
    LEFT JOIN [portal].[Users]        u ON u.userId    = w.organizerUserId
    WHERE  b.reminderSent = 0
      AND  b.status       = 'confirmed'
      AND  s.slotDateTime BETWEEN DATEADD(HOUR, 24, GETUTCDATE())
                               AND DATEADD(HOUR, 25, GETUTCDATE());
END;
GO



-- ============================================================
-- merged from: 2026.04.29_rb_webinar_invite.sql
-- ============================================================


-- ============================================================
-- Webinar: Supplier invitations, certId on Supplier, invitation
-- tracking table, and WEBINAR_INVITATION email template.
-- Date: 2026-04-29
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- 1. Add certId to Supplier (links to latest cert of the company)
-- ─────────────────────────────────────────────────────────────

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE  object_id = OBJECT_ID('[portal].[Supplier]') AND name = 'certId'
)
BEGIN
    ALTER TABLE [portal].[Supplier]
    ADD [certId] INT NULL;
END;
GO

-- Populate certId with the most recent certId for each supplier's company
UPDATE s
SET    s.certId = sub.certId
FROM   [portal].[Supplier] s
INNER JOIN (
    SELECT companyId, MAX(certId) AS certId
    FROM   [portal].[Certification]
    GROUP  BY companyId
) sub ON sub.companyId = s.companyId
WHERE  s.certId IS NULL
  AND  s.companyId IS NOT NULL;
GO

-- ─────────────────────────────────────────────────────────────
-- 2. Create WebinarInvitations table
-- ─────────────────────────────────────────────────────────────

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'WebinarInvitations' AND schema_id = SCHEMA_ID('portal'))
BEGIN
    CREATE TABLE [portal].[WebinarInvitations] (
        [invitationId]  INT IDENTITY(1,1) PRIMARY KEY,
        [webinarId]     INT            NOT NULL,
        [supplierId]    INT            NOT NULL,
        [supplierName]  NVARCHAR(200)  NOT NULL,
        [supplierEmail] NVARCHAR(200)  NOT NULL,
        [invitedAt]     DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT UQ_WebinarInvitation UNIQUE ([webinarId], [supplierId])
    );
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 3. spWebinarInvitation_Save — bulk upsert via JSON
-- ─────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE [portal].[spWebinarInvitation_Save]
    @webinarId       INT,
    @invitationsJson NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- JSON array format: [{"supplierId":1,"supplierName":"ACME","supplierEmail":"x@x.com"}, ...]
    INSERT INTO [portal].[WebinarInvitations] ([webinarId], [supplierId], [supplierName], [supplierEmail], [invitedAt])
    SELECT @webinarId, j.supplierId, j.supplierName, j.supplierEmail, GETUTCDATE()
    FROM   OPENJSON(@invitationsJson) WITH (
        supplierId    INT            '$.supplierId',
        supplierName  NVARCHAR(200)  '$.supplierName',
        supplierEmail NVARCHAR(200)  '$.supplierEmail'
    ) j
    WHERE NOT EXISTS (
        SELECT 1 FROM [portal].[WebinarInvitations] wi
        WHERE  wi.webinarId = @webinarId AND wi.supplierId = j.supplierId
    );

    SELECT @@ROWCOUNT AS insertedCount;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 4. spWebinarInvitation_Get — invitations with booking status
-- ─────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE [portal].[spWebinarInvitation_Get]
    @webinarId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT wi.invitationId,
           wi.webinarId,
           wi.supplierId,
           wi.supplierName,
           wi.supplierEmail,
           s.certId,
           wi.invitedAt,
           b.bookingId,
           b.status                                                       AS bookingStatus,
           bs.slotDateTime,
           CASE WHEN b.bookingId IS NOT NULL THEN 1 ELSE 0 END            AS isBooked
    FROM   [portal].[WebinarInvitations]    wi
    LEFT JOIN [portal].[Supplier]           s  ON s.supplierId  = wi.supplierId
    LEFT JOIN [portal].[WebinarBookings]    b  ON b.webinarId   = wi.webinarId
                                              AND LOWER(b.contactEmail) = LOWER(wi.supplierEmail)
                                              AND b.status = 'confirmed'
    LEFT JOIN [portal].[WebinarSlots]       bs ON bs.slotId     = b.slotId
    WHERE  wi.webinarId = @webinarId
    ORDER  BY wi.invitedAt ASC;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 5. spWebinarBooking_Get — add isInvited flag
-- ─────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE [portal].[spWebinarBooking_Get]
    @webinarId INT = NULL,
    @bookingId INT = NULL,
    @slotId    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT b.*,
           s.slotDateTime,
           s.capacity,
           s.bookedCount,
           s.meetingLink,
           CASE WHEN EXISTS (
               SELECT 1 FROM [portal].[WebinarInvitations] wi
               WHERE  wi.webinarId = b.webinarId
                 AND  LOWER(wi.supplierEmail) = LOWER(b.contactEmail)
           ) THEN 1 ELSE 0 END AS isInvited
    FROM   [portal].[WebinarBookings] b
    JOIN   [portal].[WebinarSlots]    s ON s.slotId = b.slotId
    WHERE  (@webinarId IS NULL OR b.webinarId = @webinarId)
      AND  (@bookingId IS NULL OR b.bookingId = @bookingId)
      AND  (@slotId    IS NULL OR b.slotId    = @slotId)
      AND  b.status = 'confirmed'
    ORDER  BY s.slotDateTime ASC, b.createdAt ASC;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 6. spSupplier_Get — return certId
-- ─────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE [portal].[spSupplier_Get]
    @companyId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT supplierId, companyId, name, email, phone, companyName, industry, spend, certId
    FROM   [portal].[Supplier]
    WHERE  (@companyId IS NULL OR companyId = @companyId)
      AND  ISNULL(isDeleted, 0) = 0
    ORDER  BY name ASC;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 7. WEBINAR_INVITATION email template
-- ─────────────────────────────────────────────────────────────

IF NOT EXISTS (SELECT 1 FROM [email].[EmailTemplates] WHERE [name] = 'WEBINAR_INVITATION')
BEGIN
    INSERT INTO [email].[NczEmailTemplates] ([name], [subject], [body], [Active])
    VALUES (
        'WEBINAR_INVITATION',
        'You''re invited: {{webinarTitle}}',
        N'<!doctype html><html><head><meta charset="UTF-8"><style>body{margin:0;padding:0;background-color:#f4f4f4;font-family:Arial,sans-serif}.wrapper{max-width:600px;margin:30px auto;background:#ffffff;border-radius:6px;overflow:hidden}.header{background-color:#f1f8e9;padding:20px 40px;display:flex;align-items:center;gap:16px;border-bottom:3px solid #2e7d32}.header img{height:40px;display:block;flex-shrink:0}.header h1{color:#2e7d32;font-size:20px;margin:0;font-weight:600}.body{padding:36px 40px;color:#333;font-size:15px;line-height:1.6}.body h2{color:#2e7d32;font-size:18px;margin-top:0}.detail-box{background:#f1f8e9;border-left:4px solid #2e7d32;border-radius:4px;padding:16px 20px;margin:20px 0}.detail-box p{margin:6px 0;font-size:14px;color:#444}.detail-box strong{color:#1b5e20}.cta-block{text-align:center;margin:28px 0}.cta-btn{background:#2e7d32;color:#ffffff;padding:14px 32px;text-decoration:none;border-radius:4px;font-weight:600;font-size:15px;display:inline-block}.footer{background:#f9f9f9;padding:20px 40px;text-align:center;font-size:12px;color:#888;border-top:1px solid #eee}.footer a{color:#2e7d32;text-decoration:none}</style></head><body><div class="wrapper"><div class="header"><img src="https://portal.nczgroup.com/assets/images/logos/ncz_logo_small.svg" alt="NCZ Logo"><h1>Webinar Invitation</h1></div><div class="body"><h2>You''re invited to join a webinar</h2><p>Dear <strong>{{supplierName}}</strong>,</p><p>You have been invited to attend the following webinar hosted by <strong>Neutral Carbon Zone</strong>:</p><div class="detail-box"><p><strong>Webinar:</strong> {{webinarTitle}}</p>{{descriptionBlock}}</div><p>Please use the button below to view available time slots and complete your booking:</p><div class="cta-block"><a href="{{bookingLink}}" class="cta-btn">&#128197; Book Your Slot</a></div><p style="font-size:13px;color:#666">If the button above does not work, copy and paste this link into your browser:<br><a href="{{bookingLink}}" style="color:#2e7d32;word-break:break-all">{{bookingLink}}</a></p><p>We look forward to seeing you there.</p><p>Best regards,<br><strong>Neutral Carbon Zone Team</strong></p></div><div class="footer">&copy; Neutral Carbon Zone &bull; <a href="https://neutralcarbonzone.com">neutralcarbonzone.com</a></div></div></body></html>',
        1
    );

    DECLARE @invTplId INT = SCOPE_IDENTITY();
    INSERT INTO [email].[EmailTemplates] ([name], [provider], [templateId])
    VALUES ('WEBINAR_INVITATION', 'ncz', @invTplId);
END;
GO

