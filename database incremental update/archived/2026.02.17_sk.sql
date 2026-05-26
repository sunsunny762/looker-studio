IF EXISTS (
    SELECT 1
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Reports].[spSilverAwardDetailData_Get]')
      AND type IN (N'P', N'PC')
)
BEGIN
    DROP PROCEDURE [Reports].[spSilverAwardDetailData_Get];
END
GO

IF EXISTS (
    SELECT 1
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Reports].[spSilverAwardByScope_Get]')
      AND type IN (N'P', N'PC')
)
BEGIN
    DROP PROCEDURE [Reports].[spSilverAwardByScope_Get];
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Reports].[spSilverCertificationCompletedData]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql
        @statement = N'CREATE PROCEDURE [Reports].[spSilverCertificationCompletedData] AS'
END
GO

ALTER PROCEDURE [Reports].[spSilverCertificationCompletedData]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Cert.certId,
        Cert.companyId,
        Cert.progId,
        Cert.status,
        Cert.emissionProfileId
    FROM portal.Certification AS Cert
    WHERE Cert.isDeleted = 0
      AND Cert.status IN (2, 3)
      AND Cert.progId = 2
    GROUP BY Cert.certId, Cert.companyId, Cert.progId, Cert.status, Cert.emissionProfileId;
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[spCertification_UpdateStatus]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql
        @statement = N'CREATE PROCEDURE [portal].[spCertification_UpdateStatus] AS'
END
GO

ALTER PROCEDURE [portal].[spCertification_UpdateStatus]
    @certId INT,
    @companyId INT,
    @status INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM [Reports].[silverAwardByScope]
        WHERE certId = @certId
    )
    AND EXISTS (
        SELECT 1
        FROM [Reports].[SilverAwardDetailData]
        WHERE certId = @certId
    )
    BEGIN
        UPDATE portal.certification
        SET status = @status
        WHERE certId = @certId AND companyId = @companyId;
    END

    EXEC portal.spCertification_Get @certId;
END
GO
