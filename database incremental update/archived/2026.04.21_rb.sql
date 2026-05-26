-- ============================================================
-- Fix spToken_Validate: widen @tokenKey from NVARCHAR(20) to
-- NVARCHAR(500) to prevent silent truncation of tokens longer
-- than 20 characters (webinar tokens are NVARCHAR(200)).
-- Truncation caused appended text to still validate correctly
-- because the extra characters were silently discarded.
-- Date: 2026-04-21
-- ============================================================

CREATE OR ALTER PROCEDURE [portal].[spToken_Validate]
    @tokenType NVARCHAR(100),
    @tokenKey  NVARCHAR(25)
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
            @tokenType IS NULL
            OR tokenType IN (
                SELECT TRIM(value)
                FROM STRING_SPLIT(@tokenType, ',')
            )
          );
END
GO

-- ============================================================
-- Update spWebinar_Get to return organizer email + name
-- so sendFeedbackEmails can use organizer as the "from" address.
-- Date: 2026-04-21
-- ============================================================

CREATE OR ALTER PROCEDURE [portal].[spWebinar_Get]
    @webinarId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT w.*,
           c.companyName,
           u.email    AS organizerEmail,
           u.fullName AS organizerName,
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
    LEFT JOIN [portal].[Users]   u ON u.userId    = w.organizerUserId
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

-- ============================================================
-- Webinar Reminder Scheduler Job
-- Runs hourly to send 24h reminder emails to webinar attendees
-- (matches the 24-25h window in spWebinarBooking_GetPendingReminders)
-- Date: 2026-04-21
-- ============================================================

SET IDENTITY_INSERT [scheduler].[ScheduledJobType] ON;
-- Job type: webinarReminder = 9  (enum index in ScheduledJobType.ts)
INSERT INTO [scheduler].[ScheduledJobType] ([id], [name])
VALUES (9, N'webinarReminder');
GO

SET IDENTITY_INSERT [scheduler].[ScheduledJobType] OFF;

-- Schedule frequency: every hour, all days (cron: 0 * * * *)
INSERT INTO [scheduler].[ScheduleFrequency] ([name], [cronDefinition], [description], [environmentKey], [logActivity])
VALUES (N'Every hour - All days', N'0 * * * *', N'Every hour, all days', N'prod', '1');
GO

-- Scheduled job: use the frequency id inserted above
-- Replace @freqId with the actual id returned by the insert above if running manually
DECLARE @freqId INT = SCOPE_IDENTITY();

INSERT INTO [scheduler].[ScheduledJob]
    ([scheduleFrequencyId], [environmentKey], [runOrder], [active], [displayName], [storedProcedureName], [description], [scheduledJobTypeId], [properties])
VALUES
    (@freqId, N'prod', 1, '1', N'WEBINAR REMINDER EMAILS', NULL, N'Hourly - sends 24h reminder emails to webinar attendees', 9, N'{}');
GO
