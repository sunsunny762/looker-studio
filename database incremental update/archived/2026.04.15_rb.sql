/*
 Navicat Premium Data Transfer

 Source Server         : NCZ [Dev]
 Source Server Type    : SQL Server
 Source Server Version : 12009114 (12.00.9114)
 Source Host           : ncz.database.windows.net:1433
 Source Catalog        : nczdev
 Source Schema         : portal

 Target Server Type    : SQL Server
 Target Server Version : 12009114 (12.00.9114)
 File Encoding         : 65001

 Date: 15/04/2026 16:40:43
*/

/*
			UPDATE cfs
			SET cfs.isDraft = NULL
			FROM portal.CertFormSubmissions AS cfs
			INNER JOIN portal.FormSubmissions AS fs ON (cfs.submissionId = fs.submissionId)
			WHERE cfs.isDraft = 1 AND fs.submissionData = '';

			UPDATE portal.CertFormSubmissions
			SET isDraft = NULL
			where isDraft = 1 and submissionId is null;

*/

-- ----------------------------
-- procedure structure for spFormSubmission_Save
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spFormSubmission_Save]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spFormSubmission_Save]
GO

CREATE PROCEDURE [portal].[spFormSubmission_Save]
    @formId INT,
    @submissionId int, 
    @userId int,
    @submissionData NVARCHAR(MAX),
    @responses NVARCHAR(MAX),
    @status int = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @currentDate DATETIME2 = GETDATE();
    DECLARE @action nvarchar(15);
    
    BEGIN TRY
        BEGIN TRANSACTION;

            if not exists (select * from portal.FormSubmissions where submissionId = @submissionId)
              BEGIN
                INSERT into [portal].[FormSubmissions] (formId, userId, submissionData, createdAt, status)
                              values (@formId, @userId, @submissionData, @currentDate, @status);
                              
                SELECT @submissionId = SCOPE_IDENTITY();
                set @action = 'insert';
              END
            else
              BEGIN
                -- Update main submission record
                UPDATE [portal].[FormSubmissions] 
                SET 
                    SubmissionData = @submissionData,
                    UpdatedAt = @currentDate,
                    Status = @status
                WHERE submissionId = @submissionId;
                
                set @action = 'update';
              END

            -- Link orphaned document uploads (submissionId=0) to the actual submission.
            -- Files uploaded before the submission record existed are stored with submissionId=0.
            -- Only considers active file-type questions (FormQuestions.questionType='file', isActive=1).
            -- Plain integer array of documentIds, e.g. "evidenceUpload":[170,169,168,167,166,165,163,162]
            IF @responses IS NOT NULL AND ISJSON(@responses) = 1
            BEGIN
                UPDATE fsd
                SET fsd.submissionId = @submissionId
                FROM portal.FormSubmissionDocuments fsd
                WHERE fsd.submissionId = 0
                  AND fsd.formId = @formId
                  AND fsd.documentId IN (
                      SELECT combined.documentId
                      FROM OPENJSON(@responses) WITH (
                          questionId    INT            '$.questionId',
                          responseValue NVARCHAR(MAX)  '$.responseValue'
                      ) r
                      INNER JOIN portal.FormQuestions fq
                          ON  fq.questionId   = r.questionId
                          AND fq.formId       = @formId
                          AND fq.questionType = 'file'
                          AND fq.isActive     = 1
                      CROSS APPLY (
                          -- plain integer array of documentIds, e.g. [170,169,168,167,166,165,163,162]
                          SELECT TRY_CAST(j.[value] AS INT)
                          FROM OPENJSON(r.responseValue) j
                          WHERE TRY_CAST(j.[value] AS INT) IS NOT NULL
                            AND j.[type] = 2  -- type 2 = number literal
                      ) combined(documentId)
                      WHERE ISJSON(r.responseValue) = 1
                  );
            END;
              
            -- Submitted
            if @status = 1 
              begin 
                -- Delete existing responses
                DELETE FROM [portal].[FormSubmissionResponses] 
                WHERE submissionId = @submissionId;
              
                -- Insert responses
                IF @responses IS NOT NULL
                BEGIN
                    INSERT INTO [portal].[FormSubmissionResponses] 
                    (submissionId, QuestionId, ResponseData, ResponseDataType)
                    SELECT 
                        @submissionId,
                        [QuestionId],
                        [ResponseValue],
                        [ResponseDataType]
                    FROM OPENJSON(@responses)
                    WITH (
                        QuestionId INT '$.questionId',
                        ResponseValue NVARCHAR(MAX) '$.responseValue',
                        ResponseDataType NVARCHAR(50) '$.responseDataType'
                    )
                    Where ResponseValue is not null;
                END;
            
            
                Update portal.CertFormSubmissions
                  set isDraft = 0,
                      isProcessed = 0,
                      userId = @userId, -- who submitted
                      dateSubmitted = @currentDate
                Where submissionId = @submissionId;
                
                set @action = 'submit';
              end
            else if @status = 0 -- Save Draft 
              begin 
                Update portal.CertFormSubmissions
                  set isDraft = 1
                Where submissionId = @submissionId;
              end;
        
            -- Audit log
            INSERT into portal.FormSubmissionAuditTrail (submissionId, userId, [action], changes, createdAt)
                                                values (@submissionId, @userId, @action, @submissionData, @currentDate);
        
        COMMIT TRANSACTION;
        
        -- Return the submission ID
        SELECT @submissionId AS submissionId;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


-- ----------------------------
-- procedure structure for spOtherSubmission_GetByProgFormId
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spOtherSubmission_GetByProgFormId]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spOtherSubmission_GetByProgFormId]
GO

CREATE PROCEDURE [portal].[spOtherSubmission_GetByProgFormId]
  @certId int,
  @progFormId int
AS
BEGIN
  -- For Tiles
    SET NOCOUNT ON;
  -- Other than Company Profile
      BEGIN
        Select cfs.certsubmissionId, cfs.submissionId, df.dataSourceId, 
               FORMAT(cfs.dateSubmitted, 'dd/MM/yyyy') as dateSubmitted, 
               case when cfs.userId=0 then cfs.notes else u.fullName end as submittedBy,
               case when cfs.userId=0 then '' else cfs.notes end as notes,
               case when cfs.isDraft = 1 then 'Draft' else 'Processed' end as formStatus,
               pf.displayName as formName,
							 case when pf.progFormId IN (209,309,409) then 1 else 0 end as isCHW, 0 as isCMP, cfs.isMBD, cfs.isDraft, cfs.isProcessed, df.dataSourceId
        From portal.CertFormSubmissions as cfs 
          INNER JOIN portal.Certification as c on (c.certId = cfs.certId)
          INNER JOIN portal.Programme as p on (c.progId = p.progId)
          INNER JOIN portal.ProgrammeForms as pf on (p.progId = pf.progId and pf.dimFormId = cfs.dimFormId)
          INNER JOIN Dimension.Form as df on (pf.dimFormId = df.id)
          LEFT JOIN portal.Users as u on (u.userId = cfs.userId)
        Where cfs.certId = @certId and pf.progFormId = @progFormId
              and ((df.dataSourceId = 1 AND cfs.isDraft = 0) OR df.dataSourceId <> 1) -- Hide pending/draft for Jotform
              and cfs.isDraft is not null
        ORDER BY cfs.dateSubmitted desc;
      END
END
GO


-- ----------------------------
-- procedure structure for spOtherSubmission_GetTiles
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spOtherSubmission_GetTiles]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spOtherSubmission_GetTiles]
GO

CREATE PROCEDURE [portal].[spOtherSubmission_GetTiles]
 @certId int,
	@uCompanyId INT = NULL
AS
BEGIN
  -- For Tiles
  SET NOCOUNT ON;
      DECLARE @locationCnt INT = 1;
			
			IF ([portal].[fnCheckUserAccess]('CERTIFICATION', @certId, @uCompanyId) = 0)
			BEGIN
					RETURN;
			END;
        -- Other Forms
        SELECT max(prg.progId) as progId,
            prg.progName, cert.certYear, c.companyName, cert.refNumber, 
            pf.progFormId, pf.dimFormId, pf.displayName AS formName, 
            SUM(CASE WHEN cfs.isDraft = 1 THEN 1 ELSE 0 END) AS draftCnt,
            SUM(CASE WHEN cfs.isDraft = 0 AND cfs.isProcessed = 0 THEN 1 ELSE 0 END) AS submitCnt,
            --SUM(CASE WHEN cfs.isProcessed = 1 THEN 1 ELSE 0 END) AS processedCnt,
            CASE 
                WHEN COUNT(cfs.submissionId) = 0 THEN 'Pending'
                --WHEN COUNT(cfs.certsubmissionId) = SUM(CASE WHEN cfs.isProcessed = 1 THEN 1 ELSE 0 END) THEN 'Processed'
                --ELSE 'Submitted'
								ELSE 'Processed'
            END AS formStatus,
            pf.displayOrder,
            df.dataSourceId,
            NULL as certsubmissionId
        FROM portal.Certification AS cert 
        INNER JOIN portal.Company AS c ON c.companyId = cert.companyId
        INNER JOIN portal.Programme AS prg ON prg.progId = cert.progId
        INNER JOIN portal.ProgrammeForms AS pf ON pf.progId = prg.progId AND pf.isActive = 1
        INNER JOIN Dimension.Form as df on df.id = pf.dimFormId and df.categoryId = 6
        LEFT JOIN portal.CertFormSubmissions AS cfs ON (pf.dimFormId = cfs.dimFormId AND cert.certId = cfs.certId and cfs.isDraft is not null)
        WHERE cert.certId = @certId
        GROUP BY prg.progName, cert.certYear, c.companyName, cert.refNumber, 
                 pf.progFormId, pf.dimFormId, df.dataSourceId, pf.displayName, pf.displayOrder

        ORDER BY displayOrder;
END
GO


-- ----------------------------
-- procedure structure for spSubmission_GetByProgFormId
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spSubmission_GetByProgFormId]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spSubmission_GetByProgFormId]
GO

CREATE PROCEDURE [portal].[spSubmission_GetByProgFormId]
  @certId int,
  @progFormId int,
  @locationId int = null
AS
BEGIN
  -- For Tiles
    SET NOCOUNT ON;
  
    if (@progFormId IN (201,301,401)) -- Company Profile
      BEGIN
        Select cfs.certsubmissionId, cfs.submissionId, df.dataSourceId, 
               FORMAT(cfs.dateSubmitted, 'dd/MM/yyyy') as dateSubmitted, 
               case when cfs.userId=0 then cfs.notes else u.fullName end as submittedBy,
               case when cfs.userId=0 then '' else cfs.notes end as notes,
               case when cfs.isDraft = 1 then 'Draft' else (case cfs.isProcessed when 1 then 'Processed' else 'Submitted' end) end as formStatus,
               l.locationName, pf.displayName as formName,
               0 as isCHW, 1 as isCMP, cfs.isMBD, cfs.isDraft, cfs.isProcessed,
               CASE WHEN (pf.progFormId IN (201,301,401)) THEN pl.locationName else null end as parentCMPLocationName
        From portal.CertFormSubmissions as cfs 
          INNER JOIN portal.Certification as c on (c.certId = cfs.certId)
          INNER JOIN portal.Programme as p on (c.progId = p.progId)
          INNER JOIN portal.ProgrammeForms as pf on (p.progId = pf.progId and pf.dimFormId = cfs.dimFormId)
          INNER JOIN Dimension.Form as df on (pf.dimFormId = df.id)
          INNER JOIN portal.Location as L on (L.locationId = cfs.locationId)
          LEFT JOIN portal.Users as u on (u.userId = cfs.userId)
          LEFT JOIN portal.CertFormSubmissions as pcfs on cfs.parentCertsubmissionId = pcfs.certsubmissionId
          LEFT JOIN portal.Location as pl on pcfs.locationId = pl.locationId
        Where cfs.certId = @certId and pf.progFormId = @progFormId and (@locationId IS NULL OR cfs.locationId IN (@locationId, 0))
              and ((df.dataSourceId = 1 AND cfs.isDraft = 0) OR df.dataSourceId <> 1) -- Hide pending/draft for Jotform
              and cfs.isDraft is not null
        ORDER BY cfs.dateSubmitted desc;
      END
    else -- Other than Company Profile
      BEGIN
        Select cfs.certsubmissionId, cfs.submissionId, df.dataSourceId, 
               FORMAT(cfs.dateSubmitted, 'dd/MM/yyyy') as dateSubmitted, 
               case when cfs.userId=0 then cfs.notes else u.fullName end as submittedBy,
               case when cfs.userId=0 then '' else cfs.notes end as notes,
               case when cfs.isDraft = 1 then 'Draft' else (case cfs.isProcessed when 1 then 'Processed' else 'Submitted' end) end as formStatus,
               l.locationName, pf.displayName as formName,
               case when pf.progFormId IN (209,309,409) then 1 else 0 end as isCHW, 0 as isCMP, cfs.isMBD, cfs.isDraft, cfs.isProcessed,
               null as parentCMPLocationName
        From portal.CertFormSubmissions as cfs 
          INNER JOIN portal.Certification as c on (c.certId = cfs.certId)
          INNER JOIN portal.Programme as p on (c.progId = p.progId)
          INNER JOIN portal.ProgrammeForms as pf on (p.progId = pf.progId and pf.dimFormId = cfs.dimFormId)
          INNER JOIN Dimension.Form as df on (pf.dimFormId = df.id)
          INNER JOIN portal.Location as L on (L.locationId = cfs.locationId)
          LEFT JOIN portal.Users as u on (u.userId = cfs.userId)
        Where cfs.certId = @certId and pf.progFormId = @progFormId and (@locationId IS NULL OR cfs.locationId IN (@locationId, 0))
              and ((df.dataSourceId = 1 AND cfs.isDraft = 0) OR df.dataSourceId <> 1) -- Hide pending/draft for Jotform
              and cfs.isDraft is not null
        ORDER BY cfs.dateSubmitted desc;
      END
END
GO


-- ----------------------------
-- procedure structure for spSubmission_GetTiles
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spSubmission_GetTiles]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spSubmission_GetTiles]
GO

CREATE PROCEDURE [portal].[spSubmission_GetTiles]
  @certId int,
  @locationId int = null,
	@uCompanyId INT = NULL
AS
BEGIN
  -- For Tiles, This shows/lists active NCZ Forms and includes inactive Jotform submission counts also
  SET NOCOUNT ON;
      DECLARE @locationCnt INT = 1;
			
			IF ([portal].[fnCheckUserAccess]('CERTIFICATION', @certId, @uCompanyId) = 0)
			BEGIN
					RETURN;
			END;

      IF @locationId IS NULL
      BEGIN
          SELECT @locationCnt = COUNT(L.locationId)
          FROM portal.Location AS L
          INNER JOIN portal.Certification AS C ON (C.companyId = L.companyId  AND L.isDeleted = 0)
          WHERE C.certId = @certId;
      END
        
        -- Other than Company profile Forms
        SELECT max(prg.progId) as progId,
            prg.progName, cert.certYear, c.companyName, cert.refNumber, 
            pf.progFormId, pf.dimFormId, pf.displayName AS formName, 
            @locationCnt as locationCnt,
            SUM(CASE WHEN cfs.isDraft = 1 THEN 1 ELSE 0 END) AS draftCnt,
            SUM(CASE WHEN cfs.isDraft = 0 AND cfs.isProcessed = 0 THEN 1 ELSE 0 END) AS submitCnt,
            SUM(CASE WHEN cfs.isProcessed = 1 THEN 1 ELSE 0 END) AS processedCnt,
            CASE 
                WHEN COUNT(cfs.submissionId) = 0 THEN 'Pending'
                WHEN COUNT(cfs.submissionId) = SUM(CASE WHEN cfs.isProcessed = 1 THEN 1 ELSE 0 END) THEN 'Processed'
                ELSE 'Submitted'
            END AS formStatus,
            pf.displayOrder,
            CASE WHEN pf.progFormId IN (209,309,409) THEN 1 ELSE 0 END AS isCHW,
            0 AS isCMP, df.dataSourceId,
            NULL as certsubmissionId,
            NULL as parentCertsubmissionId,
            NULL as parentCMPLocationName
        FROM portal.Certification AS cert 
        INNER JOIN portal.Company AS c ON c.companyId = cert.companyId
        INNER JOIN portal.Programme AS prg ON prg.progId = cert.progId
        INNER JOIN portal.ProgrammeForms AS pf ON pf.progId = prg.progId AND pf.isActive = 1
        LEFT JOIN portal.ProgrammeForms AS pfj ON pfj.progId = prg.progId AND pfj.isActive = 0 And pfj.progFormId = pf.progFormId -- Jotforms
        INNER JOIN Dimension.Form as df on df.id = pf.dimFormId and df.categoryId in (1,4,5)
        LEFT JOIN portal.CertFormSubmissions AS cfs ON (pf.dimFormId = cfs.dimFormId or (pfj.dimFormId = cfs.dimFormId and cfs.isDraft=0))
                                                       AND cert.certId = cfs.certId and cfs.isDraft is not null
                                                       AND (@locationId IS NULL OR locationId IN (@locationId, 0))
        WHERE cert.certId = @certId AND pf.progFormId NOT IN (201,301,401) 
        GROUP BY prg.progName, cert.certYear, c.companyName, cert.refNumber, 
                 pf.progFormId, pf.dimFormId, df.dataSourceId, pf.displayName, pf.displayOrder

        UNION ALL

        -- Company profile Forms
        SELECT max(prg.progId) as progId,
            prg.progName, cert.certYear, c.companyName, cert.refNumber, 
            pf.progFormId, pf.dimFormId, pf.displayName AS formName, 
            @locationCnt as locationCnt,
            SUM(CASE WHEN cfs.isDraft = 1 THEN 1 ELSE 0 END) AS draftCnt,
            SUM(CASE WHEN cfs.isDraft = 0 AND cfs.isProcessed = 0 THEN 1 ELSE 0 END) AS submitCnt,
            SUM(CASE WHEN cfs.isProcessed = 1 THEN 1 ELSE 0 END) AS processedCnt,
            CASE 
                WHEN COUNT(cfs.submissionId) = 0 THEN 'Pending'
                WHEN COUNT(cfs.submissionId) = SUM(CASE WHEN cfs.isProcessed = 1 THEN 1 ELSE 0 END) THEN 'Processed'
                ELSE 'Submitted'
            END AS formStatus,
            pf.displayOrder, 0 AS isCHW, 1 AS isCMP, df.dataSourceId,
            CASE WHEN @locationId IS NOT NULL THEN MAX(cfs.certsubmissionId) ELSE NULL END as certsubmissionId,
            CASE WHEN @locationId IS NOT NULL THEN MAX(cfs.parentCertsubmissionId) ELSE NULL END as parentCertsubmissionId,
            CASE WHEN @locationId IS NOT NULL THEN MAX(pl.locationName) ELSE NULL END as parentCMPLocationName
        FROM portal.Certification AS cert 
        INNER JOIN portal.Company AS c ON c.companyId = cert.companyId
        INNER JOIN portal.Programme AS prg ON prg.progId = cert.progId
        INNER JOIN portal.ProgrammeForms AS pf ON pf.progId = prg.progId AND pf.isActive = 1
        LEFT JOIN portal.ProgrammeForms AS pfj ON pfj.progId = prg.progId AND pfj.isActive = 0 And pfj.progFormId = pf.progFormId -- Jotforms
        INNER JOIN Dimension.Form as df on df.id = pf.dimFormId and df.categoryId in (1,4,5)
        LEFT JOIN portal.CertFormSubmissions AS cfs ON (pf.dimFormId = cfs.dimFormId or (pfj.dimFormId = cfs.dimFormId and cfs.isDraft=0))
                                                       AND cert.certId = cfs.certId and cfs.isDraft is not null
                                                       AND (@locationId IS NULL OR locationId IN (@locationId, 0))
        LEFT JOIN portal.CertFormSubmissions as pcfs ON cfs.parentCertsubmissionId = pcfs.certsubmissionId -- Parent certsubmission
        LEFT JOIN portal.Location as pl ON pcfs.locationId = pl.locationId -- Parent certsubmission's Location      
        WHERE cert.certId = @certId AND pf.progFormId IN (201,301,401)
        GROUP BY prg.progName, cert.certYear, c.companyName, cert.refNumber, 
                 pf.progFormId, pf.dimFormId, df.dataSourceId, pf.displayName, pf.displayOrder

        ORDER BY displayOrder;
END
GO


-- ----------------------------
-- procedure structure for spSubmission_Save
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spSubmission_Save]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spSubmission_Save]
GO

CREATE PROCEDURE [portal].[spSubmission_Save]
    @certId int,
    @locationId int = 0,
    @userId int,
    @dimFormId int,
    @notes nvarchar(100) = null,
    @parentCertsubmissionId int = null
AS
BEGIN
    SET NOCOUNT ON;
    Declare @certsubmissionId int;
    
    if(@parentCertsubmissionId is null)
      begin

          Declare @dataSourceId int, @formId int, @submissionId int;
          
          Select @dataSourceId = dataSourceId, @formId = sourceId from Dimension.Form where id = @dimFormId;
          
          if (@dataSourceId = 2) -- NCZForm, then add record in FormSubmissions to link with certification and show it as draft
            begin
            
              BEGIN TRY
              BEGIN TRANSACTION;
              
                INSERT into [portal].[FormSubmissions] (formId, userId, submissionData, createdAt)
                                values (@formId, @userId, '', CURRENT_TIMESTAMP);
                                
                SELECT @submissionId = SCOPE_IDENTITY();
                                
                INSERT INTO [portal].[CertFormSubmissions] (certId, submissionId, userId, dimFormId, locationId, notes, isDraft, dateSubmitted) 
                                                  VALUES (@certId, @submissionId, @userId, @dimFormId, @locationId, @notes, NULL, CURRENT_TIMESTAMP);
                                                  
                COMMIT TRANSACTION;
                                           
                SET @certsubmissionId = (SELECT SCOPE_IDENTITY());
                 
              END TRY
              BEGIN CATCH
                  ROLLBACK TRANSACTION;
                  THROW;
              END CATCH;
            end
          else -- JotForm
            begin
              INSERT INTO [portal].[CertFormSubmissions] (certId, userId, dimFormId, locationId, notes, dateSubmitted) 
                                              VALUES (@certId, @userId, @dimFormId, @locationId, @notes, CURRENT_TIMESTAMP);
                                              
              SET @certsubmissionId = (SELECT SCOPE_IDENTITY());
            end

      end
    ELSE -- for Company profile Child of other location
      begin
        INSERT INTO [portal].[CertFormSubmissions] (certId, userId, dimFormId, locationId, parentCertsubmissionId, notes, submissionId, isProcessed, isDraft, dateSubmitted) 
        Select @certId, @userId, @dimFormId, @locationId, @parentCertsubmissionId, @notes, submissionId, isProcessed, isDraft, CURRENT_TIMESTAMP
        from portal.CertFormSubmissions 
        Where certsubmissionId = @parentCertsubmissionId;
        
        SET @certsubmissionId = (SELECT SCOPE_IDENTITY());
      end
    
    Select @certsubmissionId as certsubmissionId, @certId as certId;
END
GO

