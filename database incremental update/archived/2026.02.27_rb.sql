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

 Date: 27/02/2026 14:47:44
*/


-- ----------------------------
-- procedure structure for spNCZDirectory_Get
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spNCZDirectory_Get]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spNCZDirectory_Get]
GO

CREATE PROCEDURE [portal].[spNCZDirectory_Get]
  @dirItemId INT = NULL,
  @showAll BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- Case 1: companyId + certId are valid
    SELECT DISTINCT
        ND.dirItemId,
        Crt.refNumber AS customerReference,
        Crt.certificationTaskId AS certTaskId,
        ND.isVisible,
        ND.isArchive,
        C.companyName,
        ND.salesName, ND.salesEmail, ND.salesPhone,
        ND.esgName, ND.esgEmail, ND.esgPhone,
        ND.emissionOffset,
        CASE C.industryType 
             WHEN 30 THEN C.industryTypeOther 
             ELSE DI.itemName 
        END AS industryType,
        ND.companyDescription, ND.offersDiscounts,
        ND.co2PerRevenue,
        ND.companyId,
        Nd.certId,

        -- Short Offers
        CASE 
            WHEN LEN(ND.offersDiscounts) - LEN(REPLACE(ND.offersDiscounts, ' ', '')) + 1 > 5
                THEN LEFT(ND.offersDiscounts, 
                          CHARINDEX(' ', ND.offersDiscounts + ' ', 
                          CHARINDEX(' ', ND.offersDiscounts + ' ', 
                          CHARINDEX(' ', ND.offersDiscounts + ' ', 
                          CHARINDEX(' ', ND.offersDiscounts + ' ', 
                          CHARINDEX(' ', ND.offersDiscounts + ' ') + 1) + 1) + 1) + 1)) 
                     + '...'
                ELSE ND.offersDiscounts
        END AS shortOffersDiscounts,

        -- Website & Social Links
        CASE WHEN C.website IS NULL OR C.website NOT LIKE '%[.][a-z]%' THEN ''
             WHEN C.website LIKE 'http%' THEN C.website
             ELSE 'http://' + C.website END AS website,

        CASE 
            WHEN (C.linkedInPage IS NULL OR C.linkedInPage NOT LIKE '%linkedin.%') 
                 AND (ND.linkedInPage IS NULL OR ND.linkedInPage NOT LIKE '%linkedin.%') THEN ''
            WHEN C.linkedInPage IS NULL OR C.linkedInPage NOT LIKE '%linkedin.%' THEN
                CASE 
                    WHEN ND.linkedInPage LIKE 'http%' THEN ND.linkedInPage
                    ELSE 'https://' + ND.linkedInPage
                END
            WHEN C.linkedInPage LIKE 'http%' THEN C.linkedInPage
            ELSE 'https://' + C.linkedInPage
        END AS linkedInPage,

        CASE WHEN ND.facebookPage IS NULL OR ND.facebookPage NOT LIKE '%facebook.%' THEN ''
             WHEN ND.facebookPage LIKE 'http%' THEN ND.facebookPage
             ELSE 'https://' + ND.facebookPage END AS facebookPage,

        CASE WHEN ND.instagramPage IS NULL OR ND.instagramPage NOT LIKE '%instagram.%' THEN ''
             WHEN ND.instagramPage LIKE 'http%' THEN ND.instagramPage
             ELSE 'https://' + ND.instagramPage END AS instagramPage,

        CASE WHEN C.logo LIKE 'https://app.neutralcarbonzone.com/uploads/%' 
                  THEN C.logo + '?apiKey=964f4219f34a79448399110d86da47f4'
             ELSE C.logo
        END AS logo,
        p.progName AS product

    FROM portal.NCZDirectory AS ND
         INNER JOIN portal.Company AS C ON ND.companyId = C.companyId
         LEFT JOIN portal.DropdownItems AS DI ON C.industryType = DI.itemId
         INNER JOIN portal.Certification AS Crt ON ND.certId = Crt.certId
         LEFT JOIN portal.Programme AS P ON Crt.progId = P.progId
        
    WHERE (ND.companyId IS NOT NULL AND ND.companyId <> 0)
      AND (ND.certId IS NOT NULL AND ND.certId <> 0)
      AND (
            ( @dirItemId IS NOT NULL AND ND.dirItemId = @dirItemId )
            OR
            ( @dirItemId IS NULL AND ( @showAll = 1 OR ND.isVisible = 1 ))
          )

    UNION ALL

    -- Case 2: fallback when companyId / certId invalid
    SELECT DISTINCT
        ND.dirItemId,
        ND.customerReference,
        ND.certTaskId,
        ND.isVisible,
        ND.isArchive,
        ND.companyName,
        ND.salesName, ND.salesEmail, ND.salesPhone,
        ND.esgName, ND.esgEmail, ND.esgPhone,
        ND.emissionOffset,
        ND.industryType,
        ND.companyDescription, ND.offersDiscounts,
        ND.co2PerRevenue,
        ND.companyId,
        Nd.certId,

        CASE 
            WHEN LEN(ND.offersDiscounts) - LEN(REPLACE(ND.offersDiscounts, ' ', '')) + 1 > 5
                THEN LEFT(ND.offersDiscounts, 
                          CHARINDEX(' ', ND.offersDiscounts + ' ', 
                          CHARINDEX(' ', ND.offersDiscounts + ' ', 
                          CHARINDEX(' ', ND.offersDiscounts + ' ', 
                          CHARINDEX(' ', ND.offersDiscounts + ' ', 
                          CHARINDEX(' ', ND.offersDiscounts + ' ') + 1) + 1) + 1) + 1)) 
                     + '...'
              ELSE ND.offersDiscounts
        END AS shortOffersDiscounts,

        CASE WHEN ND.website IS NULL OR ND.website NOT LIKE '%[.][a-z]%' THEN ''
             WHEN ND.website LIKE 'http%' THEN ND.website
             ELSE 'http://' + ND.website END AS website,

        CASE WHEN ND.linkedInPage IS NULL OR ND.linkedInPage NOT LIKE '%linkedin.%' THEN ''
             WHEN ND.linkedInPage LIKE 'http%' THEN ND.linkedInPage
             ELSE 'https://' + ND.linkedInPage END AS linkedInPage,

        CASE WHEN ND.facebookPage IS NULL OR ND.facebookPage NOT LIKE '%facebook.%' THEN ''
             WHEN ND.facebookPage LIKE 'http%' THEN ND.facebookPage
             ELSE 'https://' + ND.facebookPage END AS facebookPage,

        CASE WHEN ND.instagramPage IS NULL OR ND.instagramPage NOT LIKE '%instagram.%' THEN ''
             WHEN ND.instagramPage LIKE 'http%' THEN ND.instagramPage
             ELSE 'https://' + ND.instagramPage END AS instagramPage,

        CASE WHEN ND.logo LIKE 'https://app.neutralcarbonzone.com/uploads/%' 
                  THEN ND.logo + '?apiKey=964f4219f34a79448399110d86da47f4'
             ELSE ND.logo
        END AS logo,
        CF.[value] AS product

    FROM portal.NCZDirectory AS ND
         LEFT JOIN clickup.CustomField AS CF 
                ON (CF.taskId = ND.certTaskId AND CF.name = 'Product' AND CF.value IS NOT NULL)
    WHERE (ND.companyId IS NULL OR ND.companyId = 0
           OR ND.certId IS NULL OR ND.certId = 0)
      AND (
            ( @dirItemId IS NOT NULL AND ND.dirItemId = @dirItemId )
            OR
            ( @dirItemId IS NULL AND ( @showAll = 1 OR ND.isVisible = 1 ))
          )

    ORDER BY isVisible, companyName;
END
GO

