-- Add isBlueCustomer, isSilverCustomer, isGoldCustomer flags to spUser_GetbyUId
-- to support customer type detection alongside the existing isPlatinumCustomer flag.
-- progId: 1=Blue, 2=Silver, 3=Gold, 4=Platinum

IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spUser_GetbyUId]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spUser_GetbyUId]
GO

CREATE PROCEDURE [portal].[spUser_GetbyUId]
  @uId NVARCHAR(100)
AS
BEGIN
  SET NOCOUNT ON;
  
  IF @uId IS NOT NULL 
  BEGIN
	    
    Declare @CertType int;
    
      Select @CertType = max(cert.progId)
      FROM portal.Certification AS cert
      -- INNER JOIN portal.Company as c on (cert.companyId = c.companyId)
      INNER JOIN portal.Users as u on (cert.companyId = u.companyId)
      WHERE cert.isDeleted = 0
      -- AND cert.progId = 4
      AND CAST(GETDATE() AS date) BETWEEN CAST(cert.startDate AS date) AND CAST(cert.endDate AS date)
      AND U.uId = @uId;
      
    SELECT 
        U.userId,
        U.companyId,
        U.email,
        U.fullName AS displayName,
        U.status,
        UR.applicationRoleId AS roleId,
        R.name AS userRole,
        U.uId,
        CASE WHEN U.isEmailVerified = 1 THEN 1 ELSE 0 END AS emailVerified,
        CASE WHEN U.status != 1 THEN 1 ELSE 0 END AS disabled,
        CASE U.companyId 
            WHEN 0 THEN 'Neutral Carbon Zone' 
            ELSE C.companyName 
        END AS companyName,
        CASE U.companyId 
            WHEN 0 THEN '/dashboard' 
            ELSE '/certifications' 
        END AS landingPage,
        @CertType as customerType,
        C.logo as companyLogo
    FROM portal.Users AS U
        LEFT JOIN portal.Company AS C ON C.companyId = U.companyId
        INNER JOIN portal.ApplicationUserRoleGrant AS UR ON U.userId = UR.userAccountId
        INNER JOIN portal.ApplicationRole AS R ON R.id = UR.applicationRoleId
    WHERE U.isDeleted = 0 
      AND U.uId = @uId;

    -- Permissions
    SELECT 
        A.name AS applicationName, 
        F.name AS featureName, 
        FO.name AS featureOptionName
    FROM portal.Users AS U
        INNER JOIN portal.ApplicationUserRoleGrant AS UR ON U.userId = UR.userAccountId
        INNER JOIN portal.ApplicationRole AS R ON R.id = UR.applicationRoleId
        INNER JOIN portal.ApplicationRoleOption AS RO ON R.id = RO.applicationRoleId
        INNER JOIN portal.ApplicationFeatureOption AS FO ON FO.id = RO.applicationFeatureOptionId
        INNER JOIN portal.ApplicationFeature AS F ON F.id = FO.applicationFeatureId
        INNER JOIN portal.Application AS A ON A.id = R.applicationId
    WHERE RO.available = 1 
      AND U.uId = @uId;
  END
END;
GO
