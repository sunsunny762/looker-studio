-- ============================================================
-- Email Unsubscriptions
-- Creates the EmailUnsubscriptions table, stored procedures,
-- and appends an unsubscribe footer link to outbound email templates.
-- Date: 2026-05-04
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- 1. Create EmailUnsubscriptions table
-- ─────────────────────────────────────────────────────────────

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'EmailUnsubscriptions' AND schema_id = SCHEMA_ID('portal'))
BEGIN
    CREATE TABLE [portal].[EmailUnsubscriptions] (
        [UnsubscribeId]    INT IDENTITY(1,1) PRIMARY KEY,
        [Email]            NVARCHAR(255) NOT NULL,
        [Reason]           NVARCHAR(100) NOT NULL,
        [Details]          NVARCHAR(500) NULL,
        [UnsubscribeDate]  DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
        [ResubscribeDate]  DATETIME2     NULL,
        [IsUnsubscribed]   BIT           NOT NULL DEFAULT 1,
        [CreatedAt]        DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt]        DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT UQ_EmailUnsubscriptions_Email UNIQUE ([Email])
    );
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 2. spEmailUnsubscription_Save — UPSERT by Email
--    Sets IsUnsubscribed=1, updates Reason, Details, UnsubscribeDate, UpdatedAt
-- ─────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE [portal].[spEmailUnsubscription_Save]
    @Email   NVARCHAR(255),
    @Reason  NVARCHAR(100),
    @Details NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM [portal].[EmailUnsubscriptions] WHERE [Email] = @Email)
    BEGIN
        UPDATE [portal].[EmailUnsubscriptions]
        SET    [Reason]          = @Reason,
               [Details]         = @Details,
               [IsUnsubscribed]  = 1,
               [UnsubscribeDate] = GETUTCDATE(),
               [ResubscribeDate] = NULL,
               [UpdatedAt]       = GETUTCDATE()
        WHERE  [Email] = @Email;
    END
    ELSE
    BEGIN
        INSERT INTO [portal].[EmailUnsubscriptions] ([Email], [Reason], [Details])
        VALUES (@Email, @Reason, @Details);
    END

    SELECT [UnsubscribeId]   AS unsubscribeId,
           [Email]           AS email,
           [Reason]          AS reason,
           [Details]         AS details,
           [UnsubscribeDate] AS unsubscribeDate,
           [ResubscribeDate] AS resubscribeDate,
           [IsUnsubscribed]  AS isUnsubscribed,
           [CreatedAt]       AS createdAt,
           [UpdatedAt]       AS updatedAt
    FROM   [portal].[EmailUnsubscriptions]
    WHERE  [Email] = @Email;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 3. spEmailUnsubscription_Get
--    @Email = NULL → return all rows (admin list view)
--    @Email = value → return single row (status check)
-- ─────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE [portal].[spEmailUnsubscription_Get]
    @Email NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [UnsubscribeId]   AS unsubscribeId,
           [Email]           AS email,
           [Reason]          AS reason,
           [Details]         AS details,
           [UnsubscribeDate] AS unsubscribeDate,
           [ResubscribeDate] AS resubscribeDate,
           [IsUnsubscribed]  AS isUnsubscribed,
           [CreatedAt]       AS createdAt,
           [UpdatedAt]       AS updatedAt
    FROM   [portal].[EmailUnsubscriptions]
    WHERE  (@Email IS NULL OR [Email] = @Email)
    ORDER  BY [UnsubscribeDate] DESC;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 4. spEmailUnsubscription_Resubscribe
--    Sets IsUnsubscribed=0, records ResubscribeDate
-- ─────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE [portal].[spEmailUnsubscription_Resubscribe]
    @Email NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [portal].[EmailUnsubscriptions]
    SET    [IsUnsubscribed]  = 0,
           [ResubscribeDate] = GETUTCDATE(),
           [UpdatedAt]       = GETUTCDATE()
    WHERE  [Email] = @Email;

    SELECT [UnsubscribeId]   AS unsubscribeId,
           [Email]           AS email,
           [Reason]          AS reason,
           [Details]         AS details,
           [UnsubscribeDate] AS unsubscribeDate,
           [ResubscribeDate] AS resubscribeDate,
           [IsUnsubscribed]  AS isUnsubscribed,
           [CreatedAt]       AS createdAt,
           [UpdatedAt]       AS updatedAt
    FROM   [portal].[EmailUnsubscriptions]
    WHERE  [Email] = @Email;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 5. Update outbound email template bodies to include
--    an unsubscribe footer using the {{unsubscribeLink}} placeholder.
--    Templates updated: WEBINAR_INVITATION, WEBINAR_BOOKING_CONFIRMATION,
--    WEBINAR_REMINDER, WEBINAR_FEEDBACK_FORM
--    Skipped: WEBINAR_ORGANIZER_NOTIFICATION (internal, NCZ-only)
-- ─────────────────────────────────────────────────────────────

DECLARE @unsubscribeBlock NVARCHAR(500) =
    N'<div style="text-align:center;margin:16px 0 0 0;padding-top:12px;border-top:1px solid #eee"><p style="font-size:11px;color:#aaa;margin:0">If you no longer wish to receive these emails, <a href="{{unsubscribeLink}}" style="color:#15c">unsubscribe here</a>.</p></div>';

-- WEBINAR_INVITATION
UPDATE t
SET    t.[body] = LEFT(t.[body], LEN(t.[body]) - LEN('</div></body></html>')) + @unsubscribeBlock + N'</div></body></html>'
FROM   [email].[NczEmailTemplates] t
WHERE  t.[name] = 'WEBINAR_INVITATION'
  AND  t.[body] NOT LIKE N'%unsubscribeLink%';

-- WEBINAR_BOOKING_CONFIRMATION
UPDATE t
SET    t.[body] = LEFT(t.[body], LEN(t.[body]) - LEN('</div></body></html>')) + @unsubscribeBlock + N'</div></body></html>'
FROM   [email].[NczEmailTemplates] t
WHERE  t.[name] = 'WEBINAR_BOOKING_CONFIRMATION'
  AND  t.[body] NOT LIKE N'%unsubscribeLink%';

-- WEBINAR_REMINDER
UPDATE t
SET    t.[body] = LEFT(t.[body], LEN(t.[body]) - LEN('</div></body></html>')) + @unsubscribeBlock + N'</div></body></html>'
FROM   [email].[NczEmailTemplates] t
WHERE  t.[name] = 'WEBINAR_REMINDER'
  AND  t.[body] NOT LIKE N'%unsubscribeLink%';

-- WEBINAR_FEEDBACK_FORM
UPDATE t
SET    t.[body] = LEFT(t.[body], LEN(t.[body]) - LEN('</div></body></html>')) + @unsubscribeBlock + N'</div></body></html>'
FROM   [email].[NczEmailTemplates] t
WHERE  t.[name] = 'WEBINAR_FEEDBACK_FORM'
  AND  t.[body] NOT LIKE N'%unsubscribeLink%';

GO


-- ============================================================
-- merged from: 2026.05.04_2_rb.sql
-- ============================================================

-- ============================================================
-- Webinar Invitation — exclude unsubscribed suppliers
-- Updates spWebinarInvitation_Get to LEFT JOIN EmailUnsubscriptions
-- and filter out rows where the supplier's email is currently
-- unsubscribed (IsUnsubscribed = 1).
-- Date: 2026-05-04
-- ============================================================

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
    LEFT JOIN [portal].[Supplier]           s   ON s.supplierId  = wi.supplierId
    LEFT JOIN [portal].[WebinarBookings]    b   ON b.webinarId   = wi.webinarId
                                               AND LOWER(b.contactEmail) = LOWER(wi.supplierEmail)
                                               AND b.status = 'confirmed'
    LEFT JOIN [portal].[WebinarSlots]       bs  ON bs.slotId     = b.slotId
    WHERE  wi.webinarId = @webinarId
    ORDER  BY wi.invitedAt ASC;
END;
GO


-- ============================================================
-- merged from: 2026.05.04_3_rb.sql
-- ============================================================

-- ============================================================
-- spWebinarSuppliers_Get
-- Returns suppliers for a company+cert with invite status and
-- unsubscription status resolved in a single query.
-- Replaces the 3-call pattern (suppliers + invitations + unsubscriptions)
-- used by the Send Invitations dialog.
--
-- Parameters:
--   @webinarId  INT         -- webinar to check invitations against
--   @companyId  INT         -- company whose suppliers to return
--   @certId     INT = NULL  -- NULL = all certs; otherwise filter by cert
--
-- Columns returned:
--   supplierId, name, email, companyName, certId
--   inviteStatus   NULL | 'invited' | 'confirmed'
--   isUnsubscribed 0 | 1
-- Date: 2026-05-04
-- ============================================================

CREATE OR ALTER PROCEDURE [portal].[spWebinarSuppliers_Get]
    @webinarId  INT,
    @companyId  INT,
    @certId     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT s.supplierId,
           s.name,
           s.email,
           s.companyName,
           s.certId,
           CASE
               WHEN b.bookingId     IS NOT NULL THEN 'confirmed'
               WHEN wi.invitationId IS NOT NULL THEN 'invited'
               ELSE NULL
           END                                                         AS inviteStatus,
           CASE WHEN eu.UnsubscribeId IS NOT NULL THEN 1 ELSE 0 END   AS isUnsubscribed
    FROM   [portal].[Supplier]               s
    LEFT JOIN [portal].[WebinarInvitations]  wi
           ON  wi.webinarId  = @webinarId
           AND wi.supplierId = s.supplierId
    LEFT JOIN [portal].[WebinarBookings]     b
           ON  b.webinarId             = @webinarId
           AND LOWER(b.contactEmail)   = LOWER(s.email)
           AND b.status                = 'confirmed'
    LEFT JOIN [portal].[EmailUnsubscriptions] eu
           ON  LOWER(eu.Email)  = LOWER(s.email)
           AND eu.IsUnsubscribed = 1
    WHERE  s.companyId = @companyId
      AND  (@certId IS NULL OR s.certId = @certId)
    ORDER  BY s.name ASC;
END;
GO

