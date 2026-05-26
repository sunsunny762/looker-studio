-- =============================================================================
-- NCZ Cart Question Type - Database Migration
-- Date: 2026-04-01
-- Author: rb
-- Description: Creates tables and stored procedures for the cart questionType
--              in the NCZ Forms system, including payment gateway integration.
-- =============================================================================

-- =============================================================================
-- TABLE: portal.FormCartConfigurations
-- Stores per-question cart settings (one row per cart question)
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[portal].[FormCartConfigurations]') AND type = N'U')
BEGIN
    CREATE TABLE [portal].[FormCartConfigurations] (
        [cartConfigId]      INT             IDENTITY(1,1)   NOT NULL,
        [questionId]        INT             NOT NULL,
        [currency]          NVARCHAR(3)     NOT NULL DEFAULT 'GBP',   -- ISO 4217
        [paymentGateway]    NVARCHAR(50)    NOT NULL DEFAULT 'stripe', -- extensible
        [gatewayPublicKey]  NVARCHAR(200)   NULL,   -- publishable key (safe to expose)
        [successUrl]        NVARCHAR(500)   NULL,   -- override portal default
        [cancelUrl]         NVARCHAR(500)   NULL,   -- override portal default
        [successMessage]    NVARCHAR(1000)  NULL,
        [minOrderAmount]    DECIMAL(18,4)   NULL,   -- optional minimum order guard
        [taxRate]           DECIMAL(5,4)    NULL,   -- e.g. 0.2000 = 20% VAT; NULL = no tax
        [taxLabel]          NVARCHAR(50)    NULL,   -- e.g. 'VAT (20%)'
        [isActive]          BIT             NOT NULL DEFAULT 1,
        [createdAt]         DATETIME2(7)    NOT NULL DEFAULT SYSDATETIME(),
        [updatedAt]         DATETIME2(7)    NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT [PK_FormCartConfigurations] PRIMARY KEY CLUSTERED ([cartConfigId] ASC)
    );
    PRINT 'Created table portal.FormCartConfigurations';
END
GO

-- =============================================================================
-- TABLE: portal.FormCartItems
-- Pre-defined item catalog for a cart configuration
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[portal].[FormCartItems]') AND type = N'U')
BEGIN
    CREATE TABLE [portal].[FormCartItems] (
        [itemId]            INT             IDENTITY(1,1)   NOT NULL,
        [cartConfigId]      INT             NOT NULL,
        [itemKey]           NVARCHAR(100)   NOT NULL,       -- machine-readable key
        [itemLabel]         NVARCHAR(255)   NOT NULL,
        [description]       NVARCHAR(500)   NULL,
        [imageUrl]          NVARCHAR(500)   NULL,           -- optional thumbnail
        [unitPrice]         DECIMAL(18,4)   NOT NULL DEFAULT 0,
        [currency]          NVARCHAR(3)     NOT NULL DEFAULT 'GBP',
        [defaultQuantity]   INT             NOT NULL DEFAULT 1,
        [minQuantity]       INT             NOT NULL DEFAULT 0,
        [maxQuantity]       INT             NULL,           -- NULL = unlimited
        [isOptional]        BIT             NOT NULL DEFAULT 1,  -- can user set qty=0?
        [itemOrder]         INT             NOT NULL DEFAULT 0,
        [isActive]          BIT             NOT NULL DEFAULT 1,
        [createdAt]         DATETIME2(7)    NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT [PK_FormCartItems] PRIMARY KEY CLUSTERED ([itemId] ASC)
    );
    PRINT 'Created table portal.FormCartItems';
END
GO

-- =============================================================================
-- TABLE: portal.FormCartCouponCodes
-- Server-side coupon definitions (NEVER sent to client)
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[portal].[FormCartCouponCodes]') AND type = N'U')
BEGIN
    CREATE TABLE [portal].[FormCartCouponCodes] (
        [couponId]          INT             IDENTITY(1,1)   NOT NULL,
        [cartConfigId]      INT             NOT NULL,
        [couponCode]        NVARCHAR(50)    NOT NULL,
        [discountType]      NVARCHAR(10)    NOT NULL,       -- 'fixed' | 'percent'
        [discountValue]     DECIMAL(18,4)   NOT NULL,       -- amount or percentage (0-100)
        [currency]          NVARCHAR(3)     NULL,           -- relevant for 'fixed' type
        [minOrderValue]     DECIMAL(18,4)   NULL,           -- minimum subtotal to apply coupon
        [maxUses]           INT             NULL,           -- NULL = unlimited
        [usedCount]         INT             NOT NULL DEFAULT 0,
        [expiresAt]         DATETIME2(7)    NULL,           -- NULL = no expiry
        [isActive]          BIT             NOT NULL DEFAULT 1,
        [createdAt]         DATETIME2(7)    NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT [PK_FormCartCouponCodes] PRIMARY KEY CLUSTERED ([couponId] ASC),
        CONSTRAINT [UQ_FormCartCouponCodes_CartCode] UNIQUE ([cartConfigId], [couponCode])
    );
    PRINT 'Created table portal.FormCartCouponCodes';
END
GO

-- =============================================================================
-- TABLE: portal.FormCartPayments
-- Payment ledger — one row per checkout attempt
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[portal].[FormCartPayments]') AND type = N'U')
BEGIN
    CREATE TABLE [portal].[FormCartPayments] (
        [paymentId]             INT             IDENTITY(1,1)   NOT NULL,
        [submissionId]          INT             NOT NULL,
        [formId]                INT             NOT NULL,
        [userId]                INT             NULL,           -- NULL for guest checkout
        [gateway]               NVARCHAR(50)    NOT NULL DEFAULT 'stripe',
        [gatewaySessionId]      NVARCHAR(200)   NOT NULL,       -- Stripe cs_xxx
        [gatewayPaymentIntentId] NVARCHAR(200)  NULL,           -- Stripe pi_xxx (set on completion)
        [currency]              NVARCHAR(3)     NOT NULL,
        [subtotalAmount]        DECIMAL(18,4)   NOT NULL DEFAULT 0,
        [taxAmount]             DECIMAL(18,4)   NOT NULL DEFAULT 0,
        [discountAmount]        DECIMAL(18,4)   NOT NULL DEFAULT 0,
        [totalAmount]           DECIMAL(18,4)   NOT NULL DEFAULT 0,  -- amount charged
        [couponCode]            NVARCHAR(50)    NULL,
        [status]                NVARCHAR(20)    NOT NULL DEFAULT 'pending', -- pending|paid|failed|refunded
        [paidAt]                DATETIME2(7)    NULL,
        [gatewayEventId]        NVARCHAR(200)   NULL,           -- Stripe event ID (idempotency)
        [gatewayResponse]       NVARCHAR(MAX)   NULL,           -- full JSON from gateway
        [createdAt]             DATETIME2(7)    NOT NULL DEFAULT SYSDATETIME(),
        [updatedAt]             DATETIME2(7)    NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT [PK_FormCartPayments] PRIMARY KEY CLUSTERED ([paymentId] ASC)
    );

    CREATE INDEX [IX_FormCartPayments_SubmissionId] ON [portal].[FormCartPayments] ([submissionId]);
    CREATE UNIQUE INDEX [IX_FormCartPayments_GatewaySessionId] ON [portal].[FormCartPayments] ([gatewaySessionId]);
    CREATE INDEX [IX_FormCartPayments_GatewayEventId] ON [portal].[FormCartPayments] ([gatewayEventId]) WHERE [gatewayEventId] IS NOT NULL;

    PRINT 'Created table portal.FormCartPayments';
END
GO

-- =============================================================================
-- Add 'pending-payment' status support to FormSubmissions
-- status: 0=draft, 1=submitted, 2=pending-payment
-- Existing records are unaffected; just a convention — no DDL change required
-- =============================================================================

-- =============================================================================
-- STORED PROCEDURE: portal.spFormCartConfig_Get
-- Returns cart configuration, items (no coupon codes) for a given cartConfigId
-- or questionId
-- =============================================================================
IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[portal].[spFormCartConfig_Get]') AND type = N'P')
    DROP PROCEDURE [portal].[spFormCartConfig_Get];
GO

CREATE PROCEDURE [portal].[spFormCartConfig_Get]
    @cartConfigId   INT = NULL,
    @questionId     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @resolvedCartConfigId INT;

    IF @cartConfigId IS NOT NULL
        SET @resolvedCartConfigId = @cartConfigId;
    ELSE IF @questionId IS NOT NULL
        SELECT @resolvedCartConfigId = cartConfigId
        FROM [portal].[FormCartConfigurations]
        WHERE questionId = @questionId AND isActive = 1;

    IF @resolvedCartConfigId IS NULL
    BEGIN
        RAISERROR('Cart configuration not found.', 16, 1);
        RETURN;
    END

    -- Config
    SELECT
        c.cartConfigId,
        c.questionId,
        c.currency,
        c.paymentGateway,
        c.gatewayPublicKey,
        c.successUrl,
        c.cancelUrl,
        c.successMessage,
        c.minOrderAmount,
        c.taxRate,
        c.taxLabel,
        c.isActive
    FROM [portal].[FormCartConfigurations] c
    WHERE c.cartConfigId = @resolvedCartConfigId AND c.isActive = 1;

    -- Items (no coupon data)
    SELECT
        i.itemId,
        i.cartConfigId,
        i.itemKey,
        i.itemLabel,
        i.description,
        i.imageUrl,
        i.unitPrice,
        i.currency,
        i.defaultQuantity,
        i.minQuantity,
        i.maxQuantity,
        i.isOptional,
        i.itemOrder
    FROM [portal].[FormCartItems] i
    WHERE i.cartConfigId = @resolvedCartConfigId AND i.isActive = 1
    ORDER BY i.itemOrder, i.itemId;
END
GO
PRINT 'Created procedure portal.spFormCartConfig_Get';
GO

-- =============================================================================
-- STORED PROCEDURE: portal.spFormCartCoupon_Validate
-- Validates a coupon code server-side and atomically increments usedCount.
-- Returns discount calculation without revealing other coupon details.
-- =============================================================================
IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[portal].[spFormCartCoupon_Validate]') AND type = N'P')
    DROP PROCEDURE [portal].[spFormCartCoupon_Validate];
GO

CREATE PROCEDURE [portal].[spFormCartCoupon_Validate]
    @cartConfigId   INT,
    @couponCode     NVARCHAR(50),
    @orderAmount    DECIMAL(18,4)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @couponId       INT,
        @discountType   NVARCHAR(10),
        @discountValue  DECIMAL(18,4),
        @minOrderValue  DECIMAL(18,4),
        @maxUses        INT,
        @usedCount      INT,
        @expiresAt      DATETIME2(7),
        @discountAmount DECIMAL(18,4) = 0;

    SELECT
        @couponId       = couponId,
        @discountType   = discountType,
        @discountValue  = discountValue,
        @minOrderValue  = minOrderValue,
        @maxUses        = maxUses,
        @usedCount      = usedCount,
        @expiresAt      = expiresAt
    FROM [portal].[FormCartCouponCodes]
    WHERE cartConfigId = @cartConfigId
      AND couponCode   = @couponCode
      AND isActive     = 1;

    -- Not found
    IF @couponId IS NULL
    BEGIN
        SELECT 0 AS valid, 'Invalid coupon code.' AS message,
               NULL AS discountType, NULL AS discountValue, 0 AS discountAmount;
        RETURN;
    END

    -- Expired
    IF @expiresAt IS NOT NULL AND @expiresAt < SYSDATETIME()
    BEGIN
        SELECT 0 AS valid, 'This coupon has expired.' AS message,
               NULL AS discountType, NULL AS discountValue, 0 AS discountAmount;
        RETURN;
    END

    -- Max uses exceeded
    IF @maxUses IS NOT NULL AND @usedCount >= @maxUses
    BEGIN
        SELECT 0 AS valid, 'This coupon code has already been used the maximum number of times.' AS message,
               NULL AS discountType, NULL AS discountValue, 0 AS discountAmount;
        RETURN;
    END

    -- Minimum order not met
    IF @minOrderValue IS NOT NULL AND @orderAmount < @minOrderValue
    BEGIN
        SELECT 0 AS valid,
               'A minimum order of ' + CAST(@minOrderValue AS NVARCHAR) + ' is required for this coupon.' AS message,
               NULL AS discountType, NULL AS discountValue, 0 AS discountAmount;
        RETURN;
    END

    -- Calculate discount
    IF @discountType = 'percent'
        SET @discountAmount = ROUND(@orderAmount * (@discountValue / 100.0), 4);
    ELSE -- 'fixed'
        SET @discountAmount = CASE WHEN @discountValue > @orderAmount THEN @orderAmount ELSE @discountValue END;

    -- Return success (do NOT increment usedCount here — increment on payment confirmation)
    SELECT
        1                   AS valid,
        'Coupon applied.'   AS message,
        @discountType       AS discountType,
        @discountValue      AS discountValue,
        @discountAmount     AS discountAmount;
END
GO
PRINT 'Created procedure portal.spFormCartCoupon_Validate';
GO

-- =============================================================================
-- STORED PROCEDURE: portal.spFormCartPayment_Save
-- Upserts a payment record; called by API on checkout creation and webhook.
-- =============================================================================
IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[portal].[spFormCartPayment_Save]') AND type = N'P')
    DROP PROCEDURE [portal].[spFormCartPayment_Save];
GO

CREATE PROCEDURE [portal].[spFormCartPayment_Save]
    @submissionId           INT,
    @formId                 INT,
    @userId                 INT             = NULL,
    @gateway                NVARCHAR(50)    = 'stripe',
    @gatewaySessionId       NVARCHAR(200),
    @gatewayPaymentIntentId NVARCHAR(200)   = NULL,
    @currency               NVARCHAR(3),
    @subtotalAmount         DECIMAL(18,4)   = 0,
    @taxAmount              DECIMAL(18,4)   = 0,
    @discountAmount         DECIMAL(18,4)   = 0,
    @totalAmount            DECIMAL(18,4),
    @couponCode             NVARCHAR(50)    = NULL,
    @status                 NVARCHAR(20)    = 'pending',
    @paidAt                 DATETIME2(7)    = NULL,
    @gatewayEventId         NVARCHAR(200)   = NULL,
    @gatewayResponse        NVARCHAR(MAX)   = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM [portal].[FormCartPayments] WHERE gatewaySessionId = @gatewaySessionId)
    BEGIN
        UPDATE [portal].[FormCartPayments]
        SET
            [gatewayPaymentIntentId] = ISNULL(@gatewayPaymentIntentId, [gatewayPaymentIntentId]),
            [status]                 = @status,
            [paidAt]                 = ISNULL(@paidAt, [paidAt]),
            [gatewayEventId]         = ISNULL(@gatewayEventId, [gatewayEventId]),
            [gatewayResponse]        = ISNULL(@gatewayResponse, [gatewayResponse]),
            [updatedAt]              = SYSDATETIME()
        WHERE gatewaySessionId = @gatewaySessionId;
    END
    ELSE
    BEGIN
        INSERT INTO [portal].[FormCartPayments]
            ([submissionId], [formId], [userId], [gateway], [gatewaySessionId],
             [gatewayPaymentIntentId], [currency], [subtotalAmount], [taxAmount],
             [discountAmount], [totalAmount], [couponCode], [status], [paidAt],
             [gatewayEventId], [gatewayResponse])
        VALUES
            (@submissionId, @formId, @userId, @gateway, @gatewaySessionId,
             @gatewayPaymentIntentId, @currency, @subtotalAmount, @taxAmount,
             @discountAmount, @totalAmount, @couponCode, @status, @paidAt,
             @gatewayEventId, @gatewayResponse);
    END

    -- Return the saved record
    SELECT TOP 1 *
    FROM [portal].[FormCartPayments]
    WHERE gatewaySessionId = @gatewaySessionId;
END
GO
PRINT 'Created procedure portal.spFormCartPayment_Save';
GO

-- =============================================================================
-- STORED PROCEDURE: portal.spFormCartPayment_GetBySession
-- Lookup a payment record by Stripe session ID (used on return redirect)
-- =============================================================================
IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[portal].[spFormCartPayment_GetBySession]') AND type = N'P')
    DROP PROCEDURE [portal].[spFormCartPayment_GetBySession];
GO

CREATE PROCEDURE [portal].[spFormCartPayment_GetBySession]
    @gatewaySessionId NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM [portal].[FormCartPayments]
    WHERE gatewaySessionId = @gatewaySessionId;
END
GO
PRINT 'Created procedure portal.spFormCartPayment_GetBySession';
GO

-- =============================================================================
-- STORED PROCEDURE: portal.spFormCartCoupon_IncrementUsedCount
-- Called by webhook handler AFTER successful payment confirmation.
-- Separated from validation to avoid double-increment on retried requests.
-- =============================================================================
IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[portal].[spFormCartCoupon_IncrementUsedCount]') AND type = N'P')
    DROP PROCEDURE [portal].[spFormCartCoupon_IncrementUsedCount];
GO

CREATE PROCEDURE [portal].[spFormCartCoupon_IncrementUsedCount]
    @cartConfigId   INT,
    @couponCode     NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [portal].[FormCartCouponCodes]
    SET usedCount = usedCount + 1
    WHERE cartConfigId = @cartConfigId
      AND couponCode   = @couponCode
      AND isActive     = 1;
END
GO
PRINT 'Created procedure portal.spFormCartCoupon_IncrementUsedCount';
GO

PRINT '=== 2026.04.01_sk.sql completed successfully ===';
GO


-- ============================================================
-- merged from: 2026.04.01.2_rb_sp_cartconfig.sql
-- ============================================================


-- =============================================================================
-- Update portal.spFormConfigurationJSON_Get to embed cartConfig
-- Date: 2026-04-01
-- Author: rb
-- Description: Adds a cartConfig JSON block to each question of
--              questionType = 'cart'. The frontend uses this embedded config
--              to render the cart component without a second API call.
--              Items (active only) are nested inside cartConfig.
--
--              spFormCartConfig_Get remains for backend use only
--              (CartService.createCheckoutSession validation path).
-- =============================================================================

ALTER PROCEDURE portal.spFormConfigurationJSON_Get
    @FormId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @JsonResult NVARCHAR(MAX);

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
                            s.showTitleDescr,
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
                                    q.isReadonly,
                                    q.isCalculated,
                                    q.calculationFormula,
                                    q.defaultValue,
                                    q.placeholderText,
                                    q.helpText,
                                    q.displayOrder AS questionOrder,
                                    q.isVisible,
                                    q.displayWidth,
                                    q.lineBreak,
                                    -- Validation Rules
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
                                            JSON_QUERY(ISNULL((
                                                SELECT 
                                                    tcol.columnId,
                                                    tcol.columnKey,
                                                    tcol.columnLabel,
                                                    tcol.columnType,
                                                    tcol.displayOrder AS columnOrder,
                                                    tcol.isRequired,
                                                    tcol.columnWidth,
                                                    CASE 
                                                          WHEN tcol.defaultValue IS NOT NULL
                                                               AND tcol.defaultValue <> ''
                                                               AND ISJSON(tcol.defaultValue) = 1
                                                              THEN null
                                                          ELSE tcol.defaultValue
                                                    END AS defaultValue,
                                                    JSON_QUERY(
                                                      CASE 
                                                          WHEN tcol.defaultValue IS NOT NULL
                                                               AND tcol.defaultValue <> ''
                                                               AND ISJSON(tcol.defaultValue) = 1
                                                              THEN tcol.defaultValue
                                                          ELSE '[]'
                                                      END
                                                    ) AS defaultValues,
                                                    CASE 
                                                        WHEN ISJSON(tcol.columnOptions) = 1 
                                                             AND JSON_VALUE(tcol.columnOptions, '$.apiUrl') IS NOT NULL
                                                        THEN JSON_VALUE(tcol.columnOptions, '$.apiUrl')
                                                        ELSE NULL
                                                    END AS columnOptionsApi,
                                                    JSON_QUERY(
                                                        CASE 
                                                            WHEN ISJSON(tcol.columnOptions) = 1 
                                                                 AND JSON_VALUE(tcol.columnOptions, '$.apiUrl') IS NOT NULL
                                                            THEN '[]'
                                                            ELSE tcol.columnOptions
                                                        END
                                                    ) AS columnOptions,
                                                    JSON_QUERY(
                                                        CASE 
                                                            WHEN tcol.ValidationRules IS NOT NULL AND tcol.ValidationRules != '' AND ISJSON(tcol.ValidationRules) = 1
                                                                THEN tcol.ValidationRules
                                                            ELSE '{}'
                                                        END
                                                    ) AS validationRules
                                                FROM portal.FormTableColumns tcol
                                                WHERE tcol.tableConfigId = tc.tableConfigId
                                                ORDER BY tcol.displayOrder
                                                FOR JSON PATH
                                            ), '[]')) AS columns
                                        FROM portal.FormTableConfigurations tc
                                        WHERE tc.questionId = q.questionId
                                        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                                    )) AS tableConfig,

                                    -- ─── Cart Configuration ───────────────────────────────────────────
                                    -- Populated only for questionType = 'cart'.
                                    -- Embeds the full CartConfig + active items so the frontend
                                    -- needs no second API call to render the cart component.
                                    -- gatewayPublicKey (Stripe publishable key) is safe to expose here.
                                    -- Coupon codes are NEVER included.
                                    JSON_QUERY((
                                        SELECT
                                            cc.cartConfigId,
                                            cc.currency,
                                            cc.paymentGateway,
                                            cc.gatewayPublicKey,
                                            cc.successMessage,
                                            cc.minOrderAmount,
                                            cc.taxRate,
                                            cc.taxLabel,
                                            cc.isActive,
                                            JSON_QUERY(ISNULL((
                                                SELECT
                                                    ci.itemId,
                                                    ci.cartConfigId,
                                                    ci.itemKey,
                                                    ci.itemLabel,
                                                    ci.description,
                                                    ci.imageUrl,
                                                    ci.unitPrice,
                                                    ci.currency,
                                                    ci.defaultQuantity,
                                                    ci.minQuantity,
                                                    ci.maxQuantity,
                                                    ci.isOptional,
                                                    ci.itemOrder,
                                                    ci.isActive
                                                FROM portal.FormCartItems ci
                                                WHERE ci.cartConfigId = cc.cartConfigId
                                                    AND ci.isActive = 1
                                                ORDER BY ci.itemOrder
                                                FOR JSON PATH
                                            ), '[]')) AS items
                                        FROM portal.FormCartConfigurations cc
                                        WHERE cc.questionId = q.questionId
                                            AND cc.isActive = 1
                                        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                                    )) AS cartConfig

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

    SELECT @JsonResult AS FormConfiguration;
END
GO

