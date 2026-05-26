/*
 Navicat Premium Data Transfer

 Source Server         : NCZ [Dev]
 Source Server Type    : SQL Server
 Source Server Version : 12009051 (12.00.9051)
 Source Host           : ncz.database.windows.net:1433
 Source Catalog        : nczdev
 Source Schema         : portal

 Target Server Type    : SQL Server
 Target Server Version : 12009051 (12.00.9051)
 File Encoding         : 65001

 Date: 27/02/2026 14:50:36
*/


-- ----------------------------
-- procedure structure for spCertificationBlueAward_Get
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spCertificationBlueAward_Get]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spCertificationBlueAward_Get]
GO

CREATE PROCEDURE [portal].[spCertificationBlueAward_Get]
  @certSubmissionId int = null
AS
BEGIN

    -- Blue award submissions from Portal
    SELECT  
        bac.blueCertId,
        bac.documentId,
        bac.certSubmissionId,
        cfs.submissionId,
        cfs.dateSubmitted,
        --cfs.notes AS companyName,
        cfs.isProcessed,
        bac.status as statusId,
        di.itemName as status,
        bac.notes,
        bac.certTaskId as certificationTaskId,
        MAX(CASE WHEN fs.questionId = 817 THEN fs.responseData END) AS companyName,
        MAX(CASE WHEN fs.questionId = 826 THEN fs.responseData END) AS fullName,
        MAX(CASE WHEN fs.questionId = 828 THEN fs.responseData END) AS email,
        MAX(CASE WHEN fs.questionId = 829 THEN fs.responseData END) AS jobTitle,
        MAX(CASE WHEN fs.questionId = 831 THEN fs.responseData END) AS phone,
        MAX(CASE WHEN fs.questionId = 820 THEN fs.responseData END) AS website,
        MAX(CASE WHEN fs.questionId = 822 THEN JSON_VALUE(fs.responseData, '$.value') END) AS country,
        MAX(CASE WHEN fs.questionId = 825 THEN JSON_VALUE(fs.responseData, '$[0]') END) AS companyLogo
    FROM portal.CertFormSubmissions AS cfs
    INNER JOIN portal.BlueAwardCertification as bac on (cfs.certsubmissionId = bac.certSubmissionId and bac.isDeleted = 0)
    INNER JOIN portal.DropdownItems as di on (bac.status = di.itemId)
    LEFT JOIN portal.FormSubmissionResponses AS fs
        ON cfs.submissionId = fs.submissionId
       AND fs.questionId IN (817, 820, 822, 825, 826, 828, 829, 831)

    WHERE cfs.certId = 0 AND cfs.dimFormId = 29
          and ISNULL(@certSubmissionId, bac.certSubmissionId) = bac.certSubmissionId 
    GROUP BY
        bac.blueCertId,
        bac.documentId,
        bac.certSubmissionId,
        cfs.submissionId,
        cfs.dateSubmitted,
        cfs.notes,
        cfs.isProcessed,
        bac.status,
        di.itemName,
        bac.notes,
        bac.certTaskId
    ORDER BY cfs.dateSubmitted DESC;



END
GO


-- ----------------------------
-- procedure structure for spToken_Validate
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spToken_Validate]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spToken_Validate]
GO

CREATE PROCEDURE [portal].[spToken_Validate]
    @tokenType NVARCHAR(10),
    @tokenKey NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        tokenId,
        tokenKey,
        certId,
        locationId,
        dimFormId,
        CASE 
            WHEN activeTo IS NULL THEN 0           -- not expired (no expiry)
            WHEN activeTo >= GETDATE() THEN 0      -- not expired
            ELSE 1                                 -- expired
        END AS isExpired,
        isActive, properties
    FROM [portal].[Tokens]
    WHERE ( @tokenType IS NULL OR tokenType = @tokenType ) and tokenKey = @tokenKey;
END
GO


-- ----------------------------
-- procedure structure for spUser_GetbyUId
-- ----------------------------
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
	    
    Declare @PlatCnt int;
    
    Select @PlatCnt = count(*) 
      FROM portal.Certification AS cert
      -- INNER JOIN portal.Company as c on (cert.companyId = c.companyId)
      INNER JOIN portal.Users as u on (cert.companyId = u.companyId)
      WHERE cert.isDeleted = 0
        AND cert.progId = 4
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
        CASE When @PlatCnt > 0 THEN 1 
            ELSE 0 
        END AS isPlatinumCustomer,
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

