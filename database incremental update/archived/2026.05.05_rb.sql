-- ============================================================
-- Supplier.UnsubscribeId flag
-- When a supplier email is added to EmailUnsubscriptions the
-- matching Supplier row is linked via UnsubscribeId (FK).
-- On resubscribe the FK is set back to NULL, cleanly unflagging
-- the supplier without needing a separate boolean column.
--
-- Changes:
--   1. Add UnsubscribeId column to portal.Supplier
--   2. Back-fill from existing EmailUnsubscriptions records
--   3. Update spEmailUnsubscription_Save  — link Supplier on unsubscribe
--   4. Update spEmailUnsubscription_Resubscribe — NULL Supplier.UnsubscribeId on resubscribe
--   5. Update spWebinarSuppliers_Get — derive isUnsubscribed from Supplier.UnsubscribeId
--   6. Update spSupplier_Get — expose isUnsubscribed column
-- Date: 2026-05-05
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- 1. Add UnsubscribeId column to Supplier table (idempotent)
-- ─────────────────────────────────────────────────────────────
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE  object_id = OBJECT_ID('[portal].[Supplier]')
      AND  name = 'UnsubscribeId'
)
ALTER TABLE [portal].[Supplier]
    ADD [UnsubscribeId] INT NULL;
GO

-- ─────────────────────────────────────────────────────────────
-- 2. Back-fill from existing EmailUnsubscriptions
-- ─────────────────────────────────────────────────────────────
UPDATE s
SET    s.[UnsubscribeId] = eu.[UnsubscribeId]
FROM   [portal].[Supplier]               s
JOIN   [portal].[EmailUnsubscriptions]   eu
       ON  LOWER(eu.[Email]) = LOWER(s.[email])
       AND eu.[IsUnsubscribed] = 1
WHERE  s.[UnsubscribeId] IS NULL;
GO

-- ─────────────────────────────────────────────────────────────
-- 3. spEmailUnsubscription_Save — also link matching Supplier row
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

    -- Link any matching supplier to the unsubscription record
    UPDATE [portal].[Supplier]
    SET    [UnsubscribeId] = eu.[UnsubscribeId]
    FROM   [portal].[Supplier]             s
    JOIN   [portal].[EmailUnsubscriptions] eu ON eu.[Email] = @Email
    WHERE  LOWER(s.[email]) = LOWER(@Email)
      AND  s.[UnsubscribeId] IS NULL;

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
-- 4. spEmailUnsubscription_Resubscribe — NULL the Supplier FK
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

    -- Unlink supplier — sets UnsubscribeId back to NULL
    UPDATE [portal].[Supplier]
    SET    [UnsubscribeId] = NULL
    WHERE  LOWER([email]) = LOWER(@Email);

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
-- 5. spWebinarSuppliers_Get — derive isUnsubscribed from Supplier.UnsubscribeId
-- ─────────────────────────────────────────────────────────────
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
           END                                              AS inviteStatus,
           CASE WHEN s.UnsubscribeId IS NOT NULL THEN 1 ELSE 0 END AS isUnsubscribed
    FROM   [portal].[Supplier]               s
    LEFT JOIN [portal].[WebinarInvitations]  wi
           ON  wi.webinarId  = @webinarId
           AND wi.supplierId = s.supplierId
    LEFT JOIN [portal].[WebinarBookings]     b
           ON  b.webinarId           = @webinarId
           AND LOWER(b.contactEmail) = LOWER(s.email)
           AND b.status              = 'confirmed'
    WHERE  s.companyId = @companyId
      AND  (@certId IS NULL OR s.certId = @certId)
    ORDER  BY s.name ASC;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- 6. spSupplier_Get — expose isUnsubscribed column
-- ─────────────────────────────────────────────────────────────
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
        CASE WHEN s.UnsubscribeId IS NOT NULL THEN 1 ELSE 0 END AS isUnsubscribed,
        c.companyName                   AS ownerCompanyName,
        cert.refNumber                  AS certRefNumber,
        cert.certYear                   AS certYear,
        prg.progName                    AS certProgName
    FROM   [portal].[Supplier]      s
    LEFT JOIN [portal].[Company]      c    ON c.companyId = s.companyId
    LEFT JOIN [portal].[Certification] cert ON cert.certId = s.certId
    LEFT JOIN [portal].[Programme]    prg  ON prg.progId  = cert.progId
    WHERE  (@companyId IS NULL OR s.companyId = @companyId)
      AND  ISNULL(s.isDeleted, 0) = 0
    ORDER  BY s.name ASC;
END;
GO
