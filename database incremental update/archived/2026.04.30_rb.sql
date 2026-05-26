-- ============================================================
-- Add @certId parameter to spSupplier_Save
-- Imported suppliers can now be linked to a specific certification.
-- Date: 2026-04-30
-- ============================================================

CREATE OR ALTER PROCEDURE [portal].[spSupplier_Save]
    @supplierId  INT            = NULL,
    @companyId   INT            = NULL,
    @companyName NVARCHAR(50)   = NULL,
    @name        NVARCHAR(100),
    @email       NVARCHAR(50),
    @phone       NVARCHAR(20),
    @industry    NVARCHAR(50)   = NULL,
    @spend       NVARCHAR(20)   = NULL,
    @certId      INT            = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @existingSupplierId INT;

    IF @supplierId IS NOT NULL
    BEGIN
        SELECT @existingSupplierId = supplierId
        FROM   [portal].[Supplier]
        WHERE  supplierId = @supplierId;
    END
    ELSE
    BEGIN
        SELECT @existingSupplierId = supplierId
        FROM   [portal].[Supplier]
        WHERE  companyId = @companyId
          AND  email     = @email
          AND  isDeleted = 0;
    END

    IF @existingSupplierId IS NULL
    BEGIN
        INSERT INTO [portal].[Supplier] (
            companyId, name, email, phone, companyName, industry, spend, certId, isDeleted
        )
        VALUES (
            @companyId, @name, @email, @phone, @companyName, @industry, @spend, @certId, 0
        );

        SELECT SCOPE_IDENTITY() AS supplierId, 'Inserted' AS Action;
    END
    ELSE
    BEGIN
        UPDATE [portal].[Supplier]
        SET
            name        = @name,
            email       = @email,
            phone       = @phone,
            companyName = @companyName,
            industry    = @industry,
            spend       = @spend,
            -- Preserve existing certId if no new value is provided
            certId      = COALESCE(@certId, certId),
            isDeleted   = 0
        WHERE supplierId = @existingSupplierId;

        SELECT @existingSupplierId AS supplierId, 'Updated' AS Action;
    END
END;
GO
