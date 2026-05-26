/****** Object:  StoredProcedure [portal].[spFormConfigurationJSON_Get]    Script Date: 05/12/2025 17:31:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [portal].[spFormConfigurationJSON_Get]
    @FormId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @JsonResult NVARCHAR(MAX);

    -- Build JSON in a variable to avoid chunking
    SET @JsonResult = (
        SELECT 
            f.formId,
            f.formName,
            f.formDescription,
            f.isActive,
            (
                SELECT 
                    p.pageId,
                    p.pageTitle,
                    p.pageDescription,
                    p.displayOrder AS pageOrder,
                    p.isVisible,
                    -- Conditions
                    JSON_QUERY(ISNULL((
                        SELECT 
                            c.conditionId,
                            c.dependsOnQuestionId,
                            dq.questionKey as dependsOnQuestionKey,
                            c.operator,
                            c.value as expectedValue,
                            c.action
                        FROM portal.FormConditions c
                        INNER JOIN portal.FormQuestions as dq on (c.dependsOnQuestionId = dq.questionId)
                        WHERE c.controlId = p.pageId
                            AND c.ControlType = 'Page'
                            AND c.FormId = f.FormId
                            AND c.isActive = 1
                        FOR JSON PATH
                    ), '[]')) AS conditions,
                    (
                        SELECT 
                            s.sectionId,
                            s.sectionTitle,
                            s.sectionDescription,
                            s.displayOrder AS sectionOrder,
                            s.sectionType,
                            s.isVisible,
                            -- Conditions
                            JSON_QUERY(ISNULL((
                                SELECT 
                                    c.conditionId,
                                    c.dependsOnQuestionId,
                                    dq.questionKey as dependsOnQuestionKey,
                                    c.operator,
                                    c.value as expectedValue,
                                    c.action
                                FROM portal.FormConditions c
                                INNER JOIN portal.FormQuestions as dq on (c.dependsOnQuestionId = dq.questionId)
                                WHERE c.controlId = s.sectionId 
                                    AND c.ControlType = 'Section'
                                    AND c.FormId = f.FormId
                                    AND c.isActive = 1
                                FOR JSON PATH
                            ), '[]')) AS conditions,
                            (
                                SELECT 
                                    q.questionId,
                                    q.questionKey,
                                    q.questionLabel,
                                    q.questionType,
                                    q.isRequired,
                                    q.isCalculated,
                                    q.calculationFormula,
                                    q.defaultValue,
                                    q.placeholderText,
                                    q.helpText,
                                    q.displayOrder AS questionOrder,
                                    q.isVisible,
                                    q.displayWidth,
                                    q.lineBreak,
                                    -- Validation Rules - Use JSON_QUERY without quotes
                                    JSON_QUERY(
                                        CASE 
                                            WHEN q.ValidationRules IS NOT NULL AND q.ValidationRules != '' AND ISJSON(q.ValidationRules) = 1
                                                THEN q.ValidationRules
                                            ELSE '{}'
                                        END
                                    ) AS validationRules,

                                    -- Options
                                    JSON_QUERY(ISNULL((
                                        SELECT 
                                            qo.optionId,
                                            qo.optionValue,
                                            qo.optionLabel,
                                            qo.displayOrder AS optionOrder,
                                            qo.isDefault
                                        FROM portal.FormQuestionOptions qo
                                        WHERE qo.questionId = q.questionId
                                        ORDER BY qo.displayOrder
                                        FOR JSON PATH
                                    ), '[]')) AS options,

                                    -- Conditions
                                    JSON_QUERY(ISNULL((
                                        SELECT 
                                            c.conditionId,
                                            c.dependsOnQuestionId,
                                            dq.questionKey as dependsOnQuestionKey,
                                            c.operator,
                                            c.value as expectedValue,
                                            c.action
                                        FROM portal.FormConditions c
                                        INNER JOIN portal.FormQuestions as dq on (c.dependsOnQuestionId = dq.questionId)
                                        WHERE c.controlId = q.questionId 
                                            AND c.ControlType = 'Question'
                                            AND c.FormId = f.FormId
                                            AND c.isActive = 1
                                        FOR JSON PATH
                                    ), '[]')) AS conditions,

                                    -- Table Configuration
                                    JSON_QUERY((
                                        SELECT 
                                            tc.tableConfigId,
                                            tc.tableName,
                                            tc.isStaticTable,
                                            tc.minRows,
                                            tc.maxRows,

                                            -- Table Columns with proper JSON handling
                                            JSON_QUERY(ISNULL((
                                                SELECT 
                                                    tcol.columnId,
                                                    tcol.columnKey,
                                                    tcol.columnLabel,
                                                    tcol.columnType,
                                                    tcol.displayOrder AS columnOrder,
                                                    tcol.isRequired,
                                                    -- tcol.defaultValue,
                                                    tcol.columnWidth,
                                                    CASE 
                                                          WHEN tcol.defaultValue IS NOT NULL
                                                               AND tcol.defaultValue <> ''
                                                               AND ISJSON(tcol.defaultValue) = 1
                                                              THEN null
                                                          ELSE tcol.defaultValue
                                                    END
                                                      AS defaultValue,
                                                    JSON_QUERY(
                                                      CASE 
                                                          WHEN tcol.defaultValue IS NOT NULL
                                                               AND tcol.defaultValue <> ''
                                                               AND ISJSON(tcol.defaultValue) = 1
                                                              THEN tcol.defaultValue
                                                          ELSE '[]'
                                                      END
                                                    ) AS defaultValues,
                                                    -- Extract API value if exists
                                                    CASE 
                                                        WHEN ISJSON(tcol.columnOptions) = 1 
                                                             AND JSON_VALUE(tcol.columnOptions, '$.apiUrl') IS NOT NULL
                                                        THEN JSON_VALUE(tcol.columnOptions, '$.apiUrl')
                                                        ELSE NULL
                                                    END 
                                                     AS columnOptionsApi,

                                                    -- If api exists → put [] here, else put the actual value
                                                    JSON_QUERY(
                                                        CASE 
                                                            WHEN ISJSON(tcol.columnOptions) = 1 
                                                                 AND JSON_VALUE(tcol.columnOptions, '$.apiUrl') IS NOT NULL
                                                            THEN '[]'
                                                            ELSE tcol.columnOptions
                                                        END
                                                    ) AS columnOptions
--                                                     JSON_QUERY(
--                                                         CASE 
--                                                             WHEN tcol.columnOptions IS NOT NULL AND tcol.columnOptions != '' AND ISJSON(tcol.columnOptions) = 1
--                                                                 THEN tcol.columnOptions
--                                                             ELSE '[]'
--                                                         END
--                                                     ) AS columnOptions
                                                    
                                                FROM portal.FormTableColumns tcol
                                                WHERE tcol.tableConfigId = tc.tableConfigId
                                                ORDER BY tcol.displayOrder
                                                FOR JSON PATH
                                            ), '[]')) AS columns

                                        FROM portal.FormTableConfigurations tc
                                        WHERE tc.questionId = q.questionId
                                        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                                    )) AS tableConfig

                                FROM portal.FormQuestions q
                                WHERE q.sectionId = s.sectionId
                                    AND q.isActive = 1
                                ORDER BY q.displayOrder
                                FOR JSON PATH
                            ) AS questions

                        FROM portal.FormSections s
                        WHERE s.pageId = p.pageId
                            AND s.isActive = 1
                        ORDER BY s.displayOrder
                        FOR JSON PATH
                    ) AS sections

                FROM portal.FormPages p
                WHERE p.formId = f.formId
                    AND p.isActive = 1
                ORDER BY p.displayOrder
                FOR JSON PATH
            ) AS pages

        FROM portal.Forms f
        WHERE f.formId = @FormId
            AND f.isActive = 1
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );

    -- Return result
    SELECT @JsonResult AS FormConfiguration;
END
GO

