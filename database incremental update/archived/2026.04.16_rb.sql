-- ============================================================
-- Webinar Booking Module
-- Date: 2026-04-16
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- 1. TABLES
-- ─────────────────────────────────────────────────────────────

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Webinars' AND schema_id = SCHEMA_ID('portal'))
BEGIN
    CREATE TABLE [portal].[Webinars] (
        [webinarId]            INT IDENTITY(1,1) PRIMARY KEY,
        [title]                NVARCHAR(500)     NOT NULL,
        [description]          NVARCHAR(MAX)     NULL,
        [organizerUserId]      INT               NOT NULL,
        [companyId]            INT               NOT NULL,
        [tokenKey]             NVARCHAR(200)     NULL,
        [postWebinarFormToken] NVARCHAR(200)     NULL,
        [isActive]             BIT               NOT NULL DEFAULT 1,
        [createdAt]            DATETIME2         NOT NULL DEFAULT GETUTCDATE(),
        [updatedAt]            DATETIME2         NOT NULL DEFAULT GETUTCDATE()
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'WebinarSlots' AND schema_id = SCHEMA_ID('portal'))
BEGIN
    CREATE TABLE [portal].[WebinarSlots] (
        [slotId]       INT IDENTITY(1,1) PRIMARY KEY,
        [webinarId]    INT      NOT NULL,
        [slotDateTime] DATETIME2 NOT NULL,
        [capacity]     INT      NOT NULL DEFAULT 10,
        [bookedCount]  INT      NOT NULL DEFAULT 0
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'WebinarBookings' AND schema_id = SCHEMA_ID('portal'))
BEGIN
    CREATE TABLE [portal].[WebinarBookings] (
        [bookingId]    INT IDENTITY(1,1) PRIMARY KEY,
        [webinarId]    INT            NOT NULL,
        [slotId]       INT            NOT NULL,
        [companyId]    INT            NOT NULL,
        [businessName] NVARCHAR(500)  NOT NULL,
        [contactEmail] NVARCHAR(500)  NOT NULL,
        [status]       NVARCHAR(50)   NOT NULL DEFAULT 'confirmed',
        [reminderSent] BIT            NOT NULL DEFAULT 0,
        [createdAt]    DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
        [tokenKey]     NVARCHAR(200)  NULL
    );
END;

-- ─────────────────────────────────────────────────────────────
-- 2. STORED PROCEDURES
-- ─────────────────────────────────────────────────────────────

-- spWebinar_Save (upsert)
GO
CREATE OR ALTER PROCEDURE [portal].[spWebinar_Save]
    @webinarId            INT            = NULL,
    @title                NVARCHAR(500)  = NULL,
    @description          NVARCHAR(MAX)  = NULL,
    @organizerUserId      INT            = NULL,
    @companyId            INT            = NULL,
    @tokenKey             NVARCHAR(200)  = NULL,
    @postWebinarFormToken NVARCHAR(200)  = NULL,
    @isActive             BIT            = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @webinarId IS NULL OR @webinarId = 0
    BEGIN
        INSERT INTO [portal].[Webinars]
            ([title], [description], [organizerUserId], [companyId], [tokenKey], [postWebinarFormToken], [isActive], [createdAt], [updatedAt])
        VALUES
            (@title, @description, @organizerUserId, @companyId, @tokenKey, @postWebinarFormToken, @isActive, GETUTCDATE(), GETUTCDATE());
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
            [updatedAt]            = GETUTCDATE()
        WHERE [webinarId] = @webinarId;
    END;

    SELECT w.*,
           (SELECT COUNT(*) FROM [portal].[WebinarBookings] wb WHERE wb.webinarId = w.webinarId) AS totalBookings
    FROM   [portal].[Webinars] w
    WHERE  w.webinarId = @webinarId;
END;
GO

-- spWebinar_Get
CREATE OR ALTER PROCEDURE [portal].[spWebinar_Get]
    @webinarId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT w.*,
           (SELECT COUNT(*) FROM [portal].[WebinarBookings] wb WHERE wb.webinarId = w.webinarId) AS totalBookings,
           (SELECT COUNT(*) FROM [portal].[WebinarSlots]    ws WHERE ws.webinarId = w.webinarId) AS slotCount
    FROM   [portal].[Webinars] w
    WHERE  (@webinarId IS NULL OR w.webinarId = @webinarId)
      AND  w.isActive = 1
    ORDER BY w.createdAt DESC;

    IF @webinarId IS NOT NULL
    BEGIN
        -- Also return slots
        SELECT s.*,
               (s.capacity - s.bookedCount) AS remaining
        FROM   [portal].[WebinarSlots] s
        WHERE  s.webinarId = @webinarId
        ORDER  BY s.slotDateTime ASC;
    END;
END;
GO

-- spWebinar_Delete (soft delete)
CREATE OR ALTER PROCEDURE [portal].[spWebinar_Delete]
    @webinarId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [portal].[Webinars]
    SET    [isActive] = 0, [updatedAt] = GETUTCDATE()
    WHERE  [webinarId] = @webinarId;
END;
GO

-- spWebinarSlot_Save (upsert)
CREATE OR ALTER PROCEDURE [portal].[spWebinarSlot_Save]
    @slotId       INT      = NULL,
    @webinarId    INT      = NULL,
    @slotDateTime DATETIME2 = NULL,
    @capacity     INT      = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @slotId IS NULL OR @slotId = 0
    BEGIN
        INSERT INTO [portal].[WebinarSlots] ([webinarId], [slotDateTime], [capacity])
        VALUES (@webinarId, @slotDateTime, COALESCE(@capacity, 10));
        SET @slotId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE [portal].[WebinarSlots]
        SET    [slotDateTime] = COALESCE(@slotDateTime, [slotDateTime]),
               [capacity]    = COALESCE(@capacity, [capacity])
        WHERE  [slotId] = @slotId;
    END;

    SELECT s.*, (s.capacity - s.bookedCount) AS remaining
    FROM   [portal].[WebinarSlots] s
    WHERE  s.slotId = @slotId;
END;
GO

-- spWebinarSlot_Get
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

-- spWebinarBooking_Save (insert + increment bookedCount atomically)
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

    -- Check capacity
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

    -- Insert booking
    INSERT INTO [portal].[WebinarBookings]
        ([webinarId], [slotId], [companyId], [businessName], [contactEmail], [status], [tokenKey], [createdAt])
    VALUES
        (@webinarId, @slotId, @companyId, @businessName, @contactEmail, 'confirmed', @tokenKey, GETUTCDATE());

    DECLARE @bookingId INT = SCOPE_IDENTITY();

    -- Increment slot counter
    UPDATE [portal].[WebinarSlots]
    SET    bookedCount = bookedCount + 1
    WHERE  slotId = @slotId;

    COMMIT TRANSACTION;

    SELECT b.*, s.slotDateTime, s.capacity, s.bookedCount
    FROM   [portal].[WebinarBookings] b
    JOIN   [portal].[WebinarSlots]    s ON s.slotId = b.slotId
    WHERE  b.bookingId = @bookingId;
END;
GO

-- spWebinarBooking_Get
CREATE OR ALTER PROCEDURE [portal].[spWebinarBooking_Get]
    @webinarId INT = NULL,
    @bookingId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT b.*,
           s.slotDateTime,
           s.capacity,
           s.bookedCount
    FROM   [portal].[WebinarBookings] b
    JOIN   [portal].[WebinarSlots]    s ON s.slotId = b.slotId
    WHERE  (@webinarId IS NULL OR b.webinarId = @webinarId)
      AND  (@bookingId IS NULL OR b.bookingId = @bookingId)
    ORDER  BY s.slotDateTime ASC, b.createdAt ASC;
END;
GO

-- spWebinarBooking_GetPendingReminders
-- Used by scheduler: bookings where slot is 24-25h from now and reminder not yet sent
CREATE OR ALTER PROCEDURE [portal].[spWebinarBooking_GetPendingReminders]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT b.*, s.slotDateTime, w.title AS webinarTitle
    FROM   [portal].[WebinarBookings] b
    JOIN   [portal].[WebinarSlots]    s ON s.slotId    = b.slotId
    JOIN   [portal].[Webinars]        w ON w.webinarId = b.webinarId
    WHERE  b.reminderSent = 0
      AND  b.status       = 'confirmed'
      AND  s.slotDateTime BETWEEN DATEADD(HOUR, 24, GETUTCDATE())
                               AND DATEADD(HOUR, 25, GETUTCDATE());
END;
GO

-- spWebinarBooking_MarkReminderSent
CREATE OR ALTER PROCEDURE [portal].[spWebinarBooking_MarkReminderSent]
    @bookingId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [portal].[WebinarBookings]
    SET    reminderSent = 1
    WHERE  bookingId = @bookingId;
END;
GO


-- ============================================================
-- Webinar Email Templates Registration
-- Date: 2026-04-16
-- Insert into email template tables (NCZ provider)
-- ============================================================

-- These templates use {{placeholder}} syntax rendered by the NCZ email service.
-- Bodies should match the HTML in ncz-email-server/templates/webinar-*.html

-- 1. Webinar Booking Confirmation (to attendee)
IF NOT EXISTS (SELECT 1 FROM [email].[EmailTemplates] WHERE [name] = 'WEBINAR_BOOKING_CONFIRMATION')
BEGIN

    INSERT INTO [email].[NczEmailTemplates] (name, [subject], [body], Active)
    VALUES (
        'WEBINAR_BOOKING_CONFIRMATION',
        'Your Webinar Booking is Confirmed',
        N'<!doctype html><html><head><meta charset="UTF-8"><style>body{margin:0;padding:0;background-color:#f4f4f4;font-family:Arial,sans-serif}.wrapper{max-width:600px;margin:30px auto;background:#ffffff;border-radius:6px;overflow:hidden}.header{background-color:#f1f8e9;padding:20px 40px;display:flex;align-items:center;gap:16px;border-bottom:3px solid #2e7d32}.header img{height:40px;display:block;flex-shrink:0}.header h1{color:#2e7d32;font-size:20px;margin:0;font-weight:600}.body{padding:36px 40px;color:#333;font-size:15px;line-height:1.6}.body h2{color:#2e7d32;font-size:18px;margin-top:0}.detail-box{background:#f1f8e9;border-left:4px solid #2e7d32;border-radius:4px;padding:16px 20px;margin:20px 0}.detail-box p{margin:6px 0;font-size:14px;color:#444}.detail-box strong{color:#1b5e20}.footer{background:#f9f9f9;padding:20px 40px;text-align:center;font-size:12px;color:#888;border-top:1px solid #eee}.footer a{color:#2e7d32;text-decoration:none}</style></head><body><div class="wrapper"><div class="header"><img src="https://portal.nczgroup.com/assets/images/logos/ncz_logo_small.svg" alt="NCZ Logo"><h1>Webinar Booking Confirmed</h1></div><div class="body"><h2>Your place is secured!</h2><p>Dear <strong>{{businessName}}</strong>,</p><p>Thank you for registering for the upcoming webinar. Here are your booking details:</p><div class="detail-box"><p><strong>Webinar:</strong> {{webinarTitle}}</p><p><strong>Business Name:</strong> {{businessName}}</p><p><strong>Date &amp; Time:</strong> {{slotDateTime}}</p></div><p>&#128197; A calendar invitation (.ics file) is attached to this email.</p><p>If you have any questions, please contact us at <a href="mailto:techteam@nczgroup.com">techteam@nczgroup.com</a>.</p><p>Best regards,<br><strong>Neutral Carbon Zone Team</strong></p></div><div class="footer">&copy; Neutral Carbon Zone &bull; <a href="https://neutralcarbonzone.com">neutralcarbonzone.com</a></div></div></body></html>', 1
    );
    
    DECLARE @tplId1 INT = SCOPE_IDENTITY();
    INSERT INTO [email].[EmailTemplates] ([name], [provider], [templateId])
    VALUES (
        'WEBINAR_BOOKING_CONFIRMATION',
        'ncz',
        @tplId1
    );
END;

-- 2. Webinar Organizer Notification (to NCZ organizer)
IF NOT EXISTS (SELECT 1 FROM [email].[EmailTemplates] WHERE [name] = 'WEBINAR_ORGANIZER_NOTIFICATION')
BEGIN
    INSERT INTO [email].[NczEmailTemplates] (name, [subject], [body], Active)
    VALUES (
        'WEBINAR_ORGANIZER_NOTIFICATION',
        'New Webinar Booking Received',
        N'<!doctype html><html><head><meta charset="UTF-8"><style>body{margin:0;padding:0;background-color:#f4f4f4;font-family:Arial,sans-serif}.wrapper{max-width:600px;margin:30px auto;background:#ffffff;border-radius:6px;overflow:hidden}.header{background-color:#e3f2fd;padding:20px 40px;display:flex;align-items:center;gap:16px;border-bottom:3px solid #1565c0}.header img{height:40px;display:block;flex-shrink:0}.header h1{color:#1565c0;font-size:20px;margin:0;font-weight:600}.body{padding:36px 40px;color:#333;font-size:15px;line-height:1.6}.body h2{color:#1565c0;font-size:18px;margin-top:0}.detail-box{background:#e3f2fd;border-left:4px solid #1565c0;border-radius:4px;padding:16px 20px;margin:20px 0}.detail-box p{margin:6px 0;font-size:14px;color:#444}.detail-box strong{color:#0d47a1}.footer{background:#f9f9f9;padding:20px 40px;text-align:center;font-size:12px;color:#888;border-top:1px solid #eee}.footer a{color:#1565c0;text-decoration:none}</style></head><body><div class="wrapper"><div class="header"><img src="https://portal.nczgroup.com/assets/images/logos/ncz_logo_small.svg" alt="NCZ Logo"><h1>New Webinar Booking Received</h1></div><div class="body"><h2>A new attendee has registered</h2><p>A company has booked a slot for your webinar:</p><div class="detail-box"><p><strong>Webinar:</strong> {{webinarTitle}}</p><p><strong>Business Name:</strong> {{businessName}}</p><p><strong>Contact Email:</strong> {{contactEmail}}</p><p><strong>Slot:</strong> {{slotDateTime}}</p></div><p>Log in to the NCZ Portal to view all bookings.</p><p>Best regards,<br><strong>NCZ System</strong></p></div><div class="footer">&copy; Neutral Carbon Zone &bull; <a href="https://neutralcarbonzone.com">neutralcarbonzone.com</a></div></div></body></html>', 1
    );
    
    DECLARE @tplId2 INT = SCOPE_IDENTITY();
    INSERT INTO [email].[EmailTemplates] ([name], [provider], [templateId])
    VALUES (
        'WEBINAR_ORGANIZER_NOTIFICATION',
        'ncz',
        @tplId2
    );
END;

-- 3. Webinar Reminder (24h before, to attendee)
IF NOT EXISTS (SELECT 1 FROM [email].[EmailTemplates] WHERE [name] = 'WEBINAR_REMINDER')
BEGIN

    INSERT INTO [email].[NczEmailTemplates] (name, [subject], [body], Active)
    VALUES (
        'WEBINAR_REMINDER',
        'Reminder: Your Webinar is Tomorrow',
        N'<!doctype html><html><head><meta charset="UTF-8"><style>body{margin:0;padding:0;background-color:#f4f4f4;font-family:Arial,sans-serif}.wrapper{max-width:600px;margin:30px auto;background:#ffffff;border-radius:6px;overflow:hidden}.header{background-color:#fff3e0;padding:20px 40px;display:flex;align-items:center;gap:16px;border-bottom:3px solid #e65100}.header img{height:40px;display:block;flex-shrink:0}.header h1{color:#e65100;font-size:20px;margin:0;font-weight:600}.body{padding:36px 40px;color:#333;font-size:15px;line-height:1.6}.body h2{color:#e65100;font-size:18px;margin-top:0}.detail-box{background:#fff3e0;border-left:4px solid #e65100;border-radius:4px;padding:16px 20px;margin:20px 0}.detail-box p{margin:6px 0;font-size:14px;color:#444}.detail-box strong{color:#bf360c}.countdown{background:#fbe9e7;border-radius:4px;padding:12px 16px;font-size:14px;color:#c62828;font-weight:600;text-align:center;margin-top:16px}.footer{background:#f9f9f9;padding:20px 40px;text-align:center;font-size:12px;color:#888;border-top:1px solid #eee}.footer a{color:#e65100;text-decoration:none}</style></head><body><div class="wrapper"><div class="header"><img src="https://portal.nczgroup.com/assets/images/logos/ncz_logo_small.svg" alt="NCZ Logo"><h1>Webinar Reminder - Tomorrow!</h1></div><div class="body"><h2>Don''t forget - your webinar is tomorrow</h2><p>Dear <strong>{{businessName}}</strong>,</p><p>This is a friendly reminder that you have a webinar booked for <strong>tomorrow</strong>.</p><div class="detail-box"><p><strong>Webinar:</strong> {{webinarTitle}}</p><p><strong>Date &amp; Time:</strong> {{slotDateTime}}</p></div><div class="countdown">&#9200; Your webinar starts in approximately 24 hours</div><p style="margin-top:20px">If you have any questions, please contact us at <a href="mailto:techteam@nczgroup.com">techteam@nczgroup.com</a>.</p><p>Best regards,<br><strong>Neutral Carbon Zone Team</strong></p></div><div class="footer">&copy; Neutral Carbon Zone &bull; <a href="https://neutralcarbonzone.com">neutralcarbonzone.com</a></div></div></body></html>', 1
    );
    
    DECLARE @tplId3 INT = SCOPE_IDENTITY();
    INSERT INTO [email].[EmailTemplates] ([name], [provider], [templateId])
    VALUES (
        'WEBINAR_REMINDER',
        'ncz',
        @tplId3
    );
END;
