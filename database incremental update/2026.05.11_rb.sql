-- =============================================================================
-- Migration: User Login Notification - Renewal Alert
-- Date: 2026-05-11
-- Description: Creates the CertNotificationLog table and stored procedures
--              for tracking per-user, per-month renewal dialog notifications.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Table: portal.CertNotificationLog
-- ─────────────────────────────────────────────────────────────────────────────
IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[CertNotificationLog]') AND type = 'U'
)
BEGIN
    CREATE TABLE [portal].[CertNotificationLog] (
        notificationId   INT            IDENTITY(1,1) NOT NULL,
        userId           INT            NOT NULL,
        notificationType NVARCHAR(50)   NOT NULL  DEFAULT ('renewal-alert'),
        notifiedAt       DATETIME       NOT NULL  DEFAULT (GETDATE()),
        CONSTRAINT PK_CertNotificationLog PRIMARY KEY (notificationId),
        CONSTRAINT UQ_CertNotificationLog UNIQUE (userId, notificationType, notifiedAt)
    );
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Stored Procedure: spRenewalAlertCheck
--    Returns: showDialog BIT, lastEndDate NVARCHAR
--    Logic:
--      - Resolve userId / companyId from Firebase uid
--      - Skip NCZ users (companyId = 0)
--      - Skip if notification already recorded for this yearMonth
--      - Find the most recent non-deleted certification for the company
--      - Show dialog if that certifications endDate is > 12 months ago
-- ─────────────────────────────────────────────────────────────────────────────
-- ─────────────────────────────────────────────────────────────────────────────
-- spRenewalAlertCheck
-- ─────────────────────────────────────────────────────────────────────────────
IF EXISTS (SELECT * FROM sys.all_objects
           WHERE object_id = OBJECT_ID(N'[portal].[spRenewalAlertCheck]') AND type IN ('P','PC','RF','X'))
    DROP PROCEDURE [portal].[spRenewalAlertCheck]
GO

CREATE PROCEDURE [portal].[spRenewalAlertCheck]
    @uid NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @userId          INT;
    DECLARE @companyId       INT;

    SELECT @userId = U.userId, @companyId = U.companyId
    FROM portal.Users AS U
    WHERE U.uId = @uid AND U.isDeleted = 0;

    IF @userId IS NULL OR @companyId = 0
    BEGIN
        SELECT CAST(0 AS BIT) AS showDialog;
        RETURN;
    END

    -- Check cert first — skip everything if not expired
    DECLARE @IsExpired INT;
    SELECT TOP 1 @IsExpired = CASE WHEN endDate < GETDATE() THEN 1 ELSE 0 END
    FROM portal.Certification
    WHERE companyId = @companyId AND isDeleted = 0
    ORDER BY endDate DESC;

    IF @IsExpired IS NULL OR @IsExpired = 0
    BEGIN
        SELECT CAST(0 AS BIT) AS showDialog;
        RETURN;
    END

    -- Only reach here if cert IS expired — now check notification log
    DECLARE @LastNotifiedDate DATE;
    SELECT @LastNotifiedDate = CAST(MAX(notifiedAt) AS DATE)
    FROM portal.CertNotificationLog
    WHERE userId          = @userId
      AND notificationType = 'renewal-alert';

    IF @LastNotifiedDate IS NOT NULL
       AND CAST(GETDATE() AS DATE) < DATEADD(DAY, 7, @LastNotifiedDate)
    BEGIN
        SELECT CAST(0 AS BIT) AS showDialog;
        RETURN;
    END

    SELECT CAST(1 AS BIT) AS showDialog;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- spRenewalAlertDismiss
-- ─────────────────────────────────────────────────────────────────────────────
IF EXISTS (SELECT * FROM sys.all_objects
           WHERE object_id = OBJECT_ID(N'[portal].[spRenewalAlertDismiss]') AND type IN ('P','PC','RF','X'))
    DROP PROCEDURE [portal].[spRenewalAlertDismiss]
GO

CREATE PROCEDURE [portal].[spRenewalAlertDismiss]
    @uid NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @userId    INT;
    DECLARE @companyId INT;

    SELECT @userId = U.userId, @companyId = U.companyId
    FROM portal.Users AS U             -- ← was portal.UserAccount
    WHERE U.uId = @uid AND U.isDeleted = 0;

    IF @userId IS NULL OR @companyId = 0 RETURN;

    -- Only insert if no dismissal exists within the last week
    IF NOT EXISTS (
        SELECT 1 FROM portal.CertNotificationLog
        WHERE userId          = @userId
          AND notificationType = 'renewal-alert'
          AND notifiedAt       > DATEADD(WEEK, -1, GETDATE())  -- ← was inverted
    )
    BEGIN
        INSERT INTO portal.CertNotificationLog (userId, notificationType, notifiedAt)
        VALUES (@userId, 'renewal-alert', GETDATE());
    END
END
GO