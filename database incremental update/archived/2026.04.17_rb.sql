-- ============================================================
-- Webinar: add meetingLink to WebinarSlots (slot-level)
-- Date: 2026-04-17
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- 1. Add meetingLink column to WebinarSlots
-- ─────────────────────────────────────────────────────────────

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE  object_id = OBJECT_ID('[portal].[WebinarSlots]') AND name = 'meetingLink'
)
BEGIN
    ALTER TABLE [portal].[WebinarSlots]
    ADD [meetingLink] NVARCHAR(500) NULL;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 2. spWebinarSlot_Save — accept and persist meetingLink
-- ─────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE [portal].[spWebinarSlot_Save]
    @slotId       INT           = NULL,
    @webinarId    INT           = NULL,
    @slotDateTime DATETIME2     = NULL,
    @capacity     INT           = NULL,
    @meetingLink  NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @slotId IS NULL OR @slotId = 0
    BEGIN
        INSERT INTO [portal].[WebinarSlots] ([webinarId], [slotDateTime], [capacity], [meetingLink])
        VALUES (@webinarId, @slotDateTime, COALESCE(@capacity, 10), @meetingLink);
        SET @slotId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE [portal].[WebinarSlots]
        SET    [slotDateTime] = COALESCE(@slotDateTime, [slotDateTime]),
               [capacity]    = COALESCE(@capacity,     [capacity]),
               [meetingLink] = COALESCE(@meetingLink,  [meetingLink])
        WHERE  [slotId] = @slotId;
    END;

    SELECT s.*, (s.capacity - s.bookedCount) AS remaining
    FROM   [portal].[WebinarSlots] s
    WHERE  s.slotId = @slotId;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 3. spWebinarBooking_Save — return meetingLink in result
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

    SELECT b.*, s.slotDateTime, s.capacity, s.bookedCount, s.meetingLink
    FROM   [portal].[WebinarBookings] b
    JOIN   [portal].[WebinarSlots]    s ON s.slotId = b.slotId
    WHERE  b.bookingId = @bookingId;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 4. spWebinarBooking_Get — return meetingLink in result
-- ─────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE [portal].[spWebinarBooking_Get]
    @webinarId INT = NULL,
    @bookingId INT = NULL
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
    ORDER  BY s.slotDateTime ASC, b.createdAt ASC;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 5. spWebinarBooking_GetPendingReminders — return meetingLink
-- ─────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE [portal].[spWebinarBooking_GetPendingReminders]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT b.*, s.slotDateTime, s.meetingLink, w.title AS webinarTitle
    FROM   [portal].[WebinarBookings] b
    JOIN   [portal].[WebinarSlots]    s ON s.slotId    = b.slotId
    JOIN   [portal].[Webinars]        w ON w.webinarId = b.webinarId
    WHERE  b.reminderSent = 0
      AND  b.status       = 'confirmed'
      AND  s.slotDateTime BETWEEN DATEADD(HOUR, 24, GETUTCDATE())
                               AND DATEADD(HOUR, 25, GETUTCDATE());
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 6. Update stored email template HTML to include {{meetingLinkBlock}}
-- ─────────────────────────────────────────────────────────────

-- Booking confirmation: insert placeholder before the .ics note paragraph
UPDATE net
SET    net.[body] = REPLACE(
           net.[body],
           N'<p>&#128197; A calendar invitation',
           N'{{meetingLinkBlock}}<p>&#128197; A calendar invitation'
       )
FROM   [email].[NczEmailTemplates] net
JOIN   [email].[EmailTemplates]    et  ON et.templateId = net.id
WHERE  et.[name] = 'WEBINAR_BOOKING_CONFIRMATION'
  AND  net.[body] NOT LIKE N'%{{meetingLinkBlock}}%';

-- Reminder: insert placeholder before the closing paragraph
UPDATE net
SET    net.[body] = REPLACE(
           net.[body],
           N'<p style="margin-top:20px">If you have any questions',
           N'{{meetingLinkBlock}}<p style="margin-top:20px">If you have any questions'
       )
FROM   [email].[NczEmailTemplates] net
JOIN   [email].[EmailTemplates]    et  ON et.templateId = net.id
WHERE  et.[name] = 'WEBINAR_REMINDER'
  AND  net.[body] NOT LIKE N'%{{meetingLinkBlock}}%';
GO

-- ─────────────────────────────────────────────────────────────
-- 7. Register 'webinars' application feature & permissions
--    Only NCZ users (applicationRoleId = 1 / 4) should see it.
--    Matches nav item: featureName='webinars', featureOptionName='availableFromMainMenu'
-- ─────────────────────────────────────────────────────────────

IF NOT EXISTS (SELECT 1 FROM [portal].[ApplicationFeature] WHERE [name] = N'webinars')
BEGIN
    INSERT INTO [portal].[ApplicationFeature] ([applicationId], [name], [description], [displayName])
    VALUES (1, N'webinars', NULL, N'Webinars');
END;
GO

DECLARE @webinarFeatureId INT = (SELECT [id] FROM [portal].[ApplicationFeature] WHERE [name] = N'webinars');

IF NOT EXISTS (
    SELECT 1 FROM [portal].[ApplicationFeatureOption]
    WHERE [applicationFeatureId] = @webinarFeatureId AND [name] = N'availableFromMainMenu'
)
BEGIN
    INSERT INTO [portal].[ApplicationFeatureOption] ([applicationFeatureId], [name], [description], [displayName])
    VALUES (@webinarFeatureId, N'availableFromMainMenu', N'Webinars', N'Webinars');
END;
GO

-- Grant to NCZ roles (roleId 1 and 4 = NCZ Admin roles, matching the public-forms pattern).
-- available=1  → all users of these roles see the menu item by default.
-- assignable=1 → can also be individually granted/revoked per user.
DECLARE @webinarFeatureId2 INT = (SELECT [id] FROM [portal].[ApplicationFeature] WHERE [name] = N'webinars');

INSERT INTO [portal].[ApplicationRoleOption] ([applicationRoleId], [applicationFeatureOptionId], [available], [assignable])
SELECT r.roleId, fo.[id], 1, 1
FROM (VALUES (1), (4)) AS r(roleId)
CROSS JOIN [portal].[ApplicationFeatureOption] fo
INNER JOIN [portal].[ApplicationFeature]       f  ON f.[id] = fo.[applicationFeatureId]
WHERE f.[id] = @webinarFeatureId2
  AND NOT EXISTS (
      SELECT 1 FROM [portal].[ApplicationRoleOption] ro2
      WHERE ro2.[applicationRoleId]          = r.roleId
        AND ro2.[applicationFeatureOptionId] = fo.[id]
  );
GO

-- ─────────────────────────────────────────────────────────────
-- 8. Update spWebinar_Get to return companyName and slotDates
-- ─────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE [portal].[spWebinar_Get]
    @webinarId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT w.*,
           c.companyName,
           (SELECT COUNT(*) FROM [portal].[WebinarBookings] wb WHERE wb.webinarId = w.webinarId) AS totalBookings,
           (SELECT COUNT(*) FROM [portal].[WebinarSlots]    ws WHERE ws.webinarId = w.webinarId) AS slotCount,
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
