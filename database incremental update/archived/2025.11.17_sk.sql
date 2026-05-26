/****** Table [portal].[CertificationStatusHistory] ******/
-- DROP TABLE [portal].[CertificationStatusHistory];
GO

IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[CertificationStatusHistory]')
      AND type = N'U'
)
BEGIN
    CREATE TABLE [portal].[CertificationStatusHistory] (
        eventId INT IDENTITY(1,1) NOT NULL,
        companyId INT NOT NULL,
        certId INT NOT NULL,
        status INT NOT NULL DEFAULT 0,
        fromDate DATETIME NULL,
        toDate DATETIME NULL,
        userId INT NULL,
        CONSTRAINT PK_CertificationStatusHistory PRIMARY KEY (eventId)
    );
END
GO

/****** StoredProcedure [portal].[spCertification_Get] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[portal].[spCertification_Get]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE PROCEDURE [portal].[spCertification_Get] AS'
END
GO

ALTER PROCEDURE [portal].[spCertification_Get]
  @certId int = null,
  @status int = null,
  @certYear int = null,
  @progId int = null
AS
BEGIN
  SET NOCOUNT ON;
  
  IF @certId IS NULL 
  BEGIN
      SELECT Crt.*, C.companyName, 
             ISNULL(P.progName, '-') AS progName, 
             ISNULL(DI.itemName, '-') AS statusStr,
             FORMAT(Crt.startDate, 'dd/MM/yyyy') + '-' + FORMAT(Crt.endDate, 'dd/MM/yyyy') AS period,
             ISNULL(CS.submissionCnt, 0) AS submissionCnt
      FROM portal.Certification AS Crt
        INNER JOIN portal.Company AS C ON Crt.companyId = C.companyId
        LEFT JOIN portal.DropdownItems AS DI ON Crt.status = DI.itemId AND DI.groupId = 1
        LEFT JOIN portal.Programme AS P ON P.progId = Crt.progId
        LEFT JOIN (
            SELECT certId, COUNT(*) AS submissionCnt
            FROM portal.CertFormSubmissions
            WHERE submissionId IS NOT NULL
            GROUP BY certId
        ) AS CS ON CS.certId = Crt.certId
      WHERE Crt.isDeleted = 0
        AND (CASE WHEN @status IS NULL THEN 1 ELSE Crt.status END) = (CASE WHEN @status IS NULL THEN 1 ELSE @status END)
        AND (CASE WHEN @certYear IS NULL THEN 1 ELSE certYear END) = (CASE WHEN @certYear IS NULL THEN 1 ELSE @certYear END)
        AND (CASE WHEN @progId IS NULL THEN 1 ELSE Crt.progId END) = (CASE WHEN @progId IS NULL THEN 1 ELSE @progId END)
      ORDER BY C.companyName ASC;
  END
  ELSE
  BEGIN
      SELECT Crt.*, C.companyName, 
             ISNULL(P.progName, '-') AS progName, 
             ISNULL(DI.itemName, '-') AS statusStr,
             FORMAT(Crt.startDate, 'dd/MM/yyyy') + '-' + FORMAT(Crt.endDate, 'dd/MM/yyyy') AS period,
             CS.submissionCnt
      FROM portal.Certification AS Crt
        INNER JOIN portal.Company AS C ON Crt.companyId = C.companyId
        LEFT JOIN portal.DropdownItems AS DI ON Crt.status = DI.itemId AND DI.groupId = 1
        LEFT JOIN portal.Programme AS P ON P.progId = Crt.progId
        LEFT JOIN (
            SELECT certId, COUNT(*) AS submissionCnt
            FROM portal.CertFormSubmissions
            WHERE certId = @certId AND submissionId IS NOT NULL
            GROUP BY certId
        ) AS CS ON CS.certId = Crt.certId
      WHERE Crt.isDeleted = 0 AND Crt.certId = @certId
      ORDER BY C.companyName ASC;
  END

END
GO

/****** StoredProcedure [portal].[spCompany_Get] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[portal].[spCompany_Get]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE PROCEDURE [portal].[spCompany_Get] AS'
END
GO

ALTER PROCEDURE [portal].[spCompany_Get]
  @companyId int = null,
  @status bit = null
AS
BEGIN
  SET NOCOUNT ON;
  
  IF @companyId IS NULL 
  BEGIN
      SELECT C.*, 
             CASE C.status WHEN 0 THEN 'Inactive' WHEN 1 THEN 'Active' WHEN 2 THEN 'Pending' END AS statusStr,
             CASE C.industryType WHEN 30 THEN C.industryTypeOther ELSE DI.itemName END AS industryTypeStr
      FROM portal.Company AS C
        LEFT JOIN portal.DropdownItems AS DI ON C.industryType = DI.itemId
      WHERE C.isDeleted = 0
        AND (CASE WHEN @status IS NULL THEN 1 ELSE C.status END) = (CASE WHEN @status IS NULL THEN 1 ELSE @status END)
      ORDER BY C.companyName ASC;
  END
  ELSE
  BEGIN
      SELECT C.*, 
             CASE C.status WHEN 0 THEN 'Inactive' WHEN 1 THEN 'Active' WHEN 2 THEN 'Pending' END AS statusStr,
             CASE C.industryType WHEN 30 THEN C.industryTypeOther ELSE DI.itemName END AS industryTypeStr
      FROM portal.Company AS C
        LEFT JOIN portal.DropdownItems AS DI ON C.industryType = DI.itemId
      WHERE C.isDeleted = 0 AND C.companyId = @companyId
      ORDER BY C.companyName ASC;
  END

END
GO

/****** StoredProcedure [portal].[spUser_Get] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[portal].[spUser_Get]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE PROCEDURE [portal].[spUser_Get] AS'
END
GO

ALTER PROCEDURE [portal].[spUser_Get]
  @userId int = null,
  @companyId int = 0,
  @status bit = null
AS
BEGIN
  SET NOCOUNT ON;
  
  IF @userId IS NULL 
  BEGIN
      SELECT U.userId, UR.applicationRoleId AS roleId, U.companyId, 
             U.email, U.fullName, U.status, U.phone,
             CASE U.companyId WHEN 0 THEN 'Neutral Carbon Zone' ELSE C.companyName END AS companyNameStr,
             CASE U.status WHEN 0 THEN 'Inactive' WHEN 1 THEN 'Active' WHEN 2 THEN 'Pending' END AS statusStr,
             ISNULL(R.name, '-') AS userRole, U.guId
      FROM portal.Users AS U
        LEFT JOIN portal.Company AS C ON C.companyId = U.companyId
        INNER JOIN portal.ApplicationUserRoleGrant AS UR ON U.userId = UR.userAccountId
        INNER JOIN portal.ApplicationRole AS R ON R.id = UR.applicationRoleId
      WHERE U.isDeleted = 0
        AND (CASE WHEN @status IS NULL THEN 1 ELSE U.status END) = (CASE WHEN @status IS NULL THEN 1 ELSE @status END)
        AND (CASE WHEN @companyId = 0 THEN 1 ELSE U.companyId END) = (CASE WHEN @companyId = 0 THEN 1 ELSE @companyId END)
      ORDER BY U.fullName;
  END
  ELSE
  BEGIN
      SELECT U.userId, UR.applicationRoleId AS roleId, U.companyId, 
             U.email, U.fullName, U.status, U.phone,
             CASE U.companyId WHEN 0 THEN 'Neutral Carbon Zone' ELSE C.companyName END AS companyNameStr,
             CASE U.status WHEN 0 THEN 'Inactive' WHEN 1 THEN 'Active' WHEN 2 THEN 'Pending' END AS statusStr,
             ISNULL(R.name, '-') AS userRole, U.guId
      FROM portal.Users AS U
        LEFT JOIN portal.Company AS C ON C.companyId = U.companyId
        INNER JOIN portal.ApplicationUserRoleGrant AS UR ON U.userId = UR.userAccountId
        INNER JOIN portal.ApplicationRole AS R ON R.id = UR.applicationRoleId
      WHERE U.isDeleted = 0 AND U.userId = @userId
      ORDER BY U.fullName;
  END

END
GO


/****** StoredProcedure [portal].[spCertification_Save] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[portal].[spCertification_Save]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE PROCEDURE [portal].[spCertification_Save] AS'
END
GO

ALTER PROCEDURE [portal].[spCertification_Save]
   @certId INT = NULL,
    @companyId INT,
    @progId INT,
    @startDate DATETIME2(7),
    @refNumber NVARCHAR(25),
    @status INT,
    @description NVARCHAR(255),
    @certificationTaskId NVARCHAR(25),
    @userId INT = NULL
AS
BEGIN

  SET NOCOUNT ON;

  IF @certId IS NULL
  BEGIN
      INSERT INTO portal.certification (
          companyId, progId, startDate, endDate, status, refNumber,
          description, certificationTaskId, certYear, isDeleted
      )
      VALUES (
          @companyId, @progId, @startDate,
          DATEADD(DAY, -1, DATEADD(YEAR, 1, @startDate)), @status, @refNumber,
          @description, @certificationTaskId, YEAR(@startDate), 0
      );

      SET @certId = SCOPE_IDENTITY();
  END
  ELSE
  BEGIN
      UPDATE portal.certification
      SET 
          companyId = @companyId,
          progId = @progId,
          startDate = @startDate,
          endDate = DATEADD(DAY, -1, DATEADD(YEAR, 1, @startDate)),
          status = @status,
          refNumber = @refNumber,
          description = @description,
          certificationTaskId = @certificationTaskId,
          certYear = YEAR(@startDate)
      WHERE certId = @certId;
  END

  IF @certId IS NOT NULL
  BEGIN
      EXEC [portal].[spCertificationStatusHistory_Save]
          @companyId = @companyId,
          @certId = @certId,
          @status = @status,
          @userId = @userId;
  END

  IF @certId IS NOT NULL
  BEGIN
      EXEC portal.spCertification_Get @certId;
  END

END
GO


/****** StoredProcedure [portal].[spCertificationStatusHistory_Save] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[portal].[spCertificationStatusHistory_Save]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE PROCEDURE [portal].[spCertificationStatusHistory_Save] AS'
END
GO

ALTER PROCEDURE [portal].[spCertificationStatusHistory_Save]
    @companyId INT,
    @certId INT,
    @status INT,
    @userId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @existingStatus INT;
    DECLARE @eventId INT;

    SELECT TOP 1 
        @existingStatus = status,
        @eventId = eventId
    FROM portal.certificationStatusHistory
    WHERE companyId = @companyId
      AND certId = @certId
    ORDER BY eventId DESC;

    IF @existingStatus IS NULL
    BEGIN
        INSERT INTO portal.certificationStatusHistory
            (companyId, certId, status, fromDate, userId)
        VALUES (@companyId, @certId, @status, GETDATE(), @userId);
    END
    ELSE
    BEGIN
        IF @existingStatus <> @status
        BEGIN
            UPDATE portal.certificationStatusHistory
            SET toDate = GETDATE()
            WHERE eventId = @eventId;

            INSERT INTO portal.certificationStatusHistory
                (companyId, certId, status, fromDate, userId)
            VALUES (@companyId, @certId, @status, GETDATE(), @userId);
        END
    END
END
GO
