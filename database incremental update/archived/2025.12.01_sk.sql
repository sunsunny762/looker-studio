/****** StoredProcedure [portal].[spSupplierStatusHistory_Save] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[portal].[spSupplierStatusHistory_Save]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE PROCEDURE [portal].[spSupplierStatusHistory_Save] AS'
END
GO

ALTER PROCEDURE [portal].[spSupplierStatusHistory_Save]
    @companyId INT,
    @eventType VARCHAR(20),
    @uId NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @userId INT = NULL;

    IF @uId IS NOT NULL
    BEGIN
        SELECT TOP 1 @userId = userId
        FROM portal.Users
        WHERE uId = @uId
          AND isDeleted = 0;
    END

    INSERT INTO portal.SupplierStatusHistory (
        companyId,
        eventType,
        updatedDate,
        userId
    )
    VALUES (
        @companyId,
        @eventType,
        GETDATE(),
        @userId
    );

    SELECT 
        SCOPE_IDENTITY() AS eventId,
        @userId AS userId,
        'Inserted' AS Action;
END
GO
