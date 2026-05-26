-- ============================================================
-- Webinar: Feedback Form Email Template
-- Date: 2026-04-20
-- Add WEBINAR_FEEDBACK_FORM email template
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM [email].[EmailTemplates] WHERE [name] = 'WEBINAR_FEEDBACK_FORM')
BEGIN

    INSERT INTO [email].[NczEmailTemplates] (name, [subject], [body], Active)
    VALUES (
        'WEBINAR_FEEDBACK_FORM',
        'Share your feedback on {{webinarTitle}}',
        N'<!doctype html><html><head><meta charset="UTF-8"><style>body{margin:0;padding:0;background-color:#f4f4f4;font-family:Arial,sans-serif}.wrapper{max-width:600px;margin:30px auto;background:#ffffff;border-radius:6px;overflow:hidden}.header{background-color:#f1f8e9;padding:20px 40px;display:flex;align-items:center;gap:16px;border-bottom:3px solid #2e7d32}.header img{height:40px;display:block;flex-shrink:0}.header h1{color:#2e7d32;font-size:20px;margin:0;font-weight:600}.body{padding:36px 40px;color:#333;font-size:15px;line-height:1.6}.body h2{color:#2e7d32;font-size:18px;margin-top:0}.detail-box{background:#f1f8e9;border-left:4px solid #2e7d32;border-radius:4px;padding:16px 20px;margin:20px 0}.detail-box p{margin:6px 0;font-size:14px;color:#444}.detail-box strong{color:#1b5e20}.cta-block{text-align:center;margin:28px 0}.cta-btn{background:#2e7d32;color:#ffffff;padding:14px 32px;text-decoration:none;border-radius:4px;font-weight:600;font-size:15px;display:inline-block}.footer{background:#f9f9f9;padding:20px 40px;text-align:center;font-size:12px;color:#888;border-top:1px solid #eee}.footer a{color:#2e7d32;text-decoration:none}</style></head><body><div class="wrapper"><div class="header"><img src="https://portal.nczgroup.com/assets/images/logos/ncz_logo_small.svg" alt="NCZ Logo"><h1>Post-Webinar Feedback</h1></div><div class="body"><h2>We''d love to hear from you!</h2><p>Dear <strong>{{businessName}}</strong>,</p><p>Thank you for attending the <strong>{{webinarTitle}}</strong> webinar. Your feedback is very important to us and helps us improve future sessions.</p><p>Please take a few minutes to complete our short feedback form:</p><div class="cta-block"><a href="{{feedbackFormUrl}}" class="cta-btn">&#128203; Complete Feedback Form</a></div><p style="font-size:13px;color:#666">If the button above does not work, copy and paste this link into your browser:<br><a href="{{feedbackFormUrl}}" style="color:#2e7d32;word-break:break-all">{{feedbackFormUrl}}</a></p><p>Thank you for your time and we hope to see you at future events.</p><p>Best regards,<br><strong>Neutral Carbon Zone Team</strong></p></div><div class="footer">&copy; Neutral Carbon Zone &bull; <a href="https://neutralcarbonzone.com">neutralcarbonzone.com</a></div></div></body></html>',
        1
    );

    DECLARE @tplId INT = SCOPE_IDENTITY();
    INSERT INTO [email].[EmailTemplates] ([name], [provider], [templateId])
    VALUES (
        'WEBINAR_FEEDBACK_FORM',
        'ncz',
        @tplId
    );
END;

-- ============================================================
-- Include organizer email + name in webinar booking results
-- Source: portal.Users.email / fullName via organizerUserId
-- Date: 2026-04-20
-- ============================================================

-- spWebinarBooking_Save: add organizer email + name to result set
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

    SELECT b.*, s.slotDateTime, s.capacity, s.bookedCount, s.meetingLink,
           w.title       AS webinarTitle,
           u.email       AS organizerEmail,
           u.fullName    AS organizerName
    FROM   [portal].[WebinarBookings] b
    JOIN   [portal].[WebinarSlots]    s ON s.slotId    = b.slotId
    JOIN   [portal].[Webinars]        w ON w.webinarId = b.webinarId
    LEFT JOIN [portal].[Users]        u ON u.userId    = w.organizerUserId
    WHERE  b.bookingId = @bookingId;
END;
GO

-- spWebinarBooking_GetPendingReminders: add organizer email + name
CREATE OR ALTER PROCEDURE [portal].[spWebinarBooking_GetPendingReminders]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT b.*, s.slotDateTime, s.meetingLink,
           w.title    AS webinarTitle,
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
-- Add totalCapacity to spWebinar_Get result set
-- Date: 2026-04-20
-- ============================================================

CREATE OR ALTER PROCEDURE [portal].[spWebinar_Get]
    @webinarId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT w.*,
           c.companyName,
           (SELECT COUNT(*)            FROM [portal].[WebinarBookings] wb WHERE wb.webinarId = w.webinarId) AS totalBookings,
           (SELECT COUNT(*)            FROM [portal].[WebinarSlots]    ws WHERE ws.webinarId = w.webinarId) AS slotCount,
           (SELECT ISNULL(SUM(ws3.capacity), 0)
            FROM   [portal].[WebinarSlots] ws3 WHERE ws3.webinarId = w.webinarId)                          AS totalCapacity,
           (
               SELECT STRING_AGG(FORMAT(ws2.slotDateTime, 'dd MMM yyyy HH:mm'), ', ')
               WITHIN GROUP (ORDER BY ws2.slotDateTime)
               FROM [portal].[WebinarSlots] ws2
               WHERE ws2.webinarId = w.webinarId
           ) AS slotDates
    FROM   [portal].[Webinars] w
    LEFT JOIN [portal].[Company] c ON c.companyId = w.companyId
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
