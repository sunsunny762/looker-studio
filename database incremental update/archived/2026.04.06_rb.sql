-- =============================================================================
-- NCZ Cart Payment — Follow-up DB changes
-- Date: 2026-04-06
-- Author: rb
-- Description:
--   1. spFormSubmission_UpdateStatus  — update only the status column for a
--      submission (avoids overwriting responses/submissionData on payment confirm).
--   2. spFormCartPayment_GetBySubmission — fetch the latest payment record for
--      a given submissionId (used by form view-mode to show payment details).
-- =============================================================================

-- =============================================================================
-- 1. STORED PROCEDURE: portal.spFormSubmission_UpdateStatus
--    Updates ONLY the status column for a given submissionId.
--    Called by cart webhook and session-verify instead of spFormSubmission_Save,
--    so that the saved form responses/submissionData are never overwritten.
-- =============================================================================
IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[portal].[spFormSubmission_UpdateStatus]') AND type = N'P')
    DROP PROCEDURE [portal].[spFormSubmission_UpdateStatus];
GO

CREATE PROCEDURE [portal].[spFormSubmission_UpdateStatus]
    @submissionId   INT,
    @status         INT      -- 0=draft, 1=submitted, 2=pending-payment
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [portal].[FormSubmissions]
    SET    [status]    = @status,
           [updatedAt] = SYSDATETIME()
    WHERE  [submissionId] = @submissionId;
END
GO
PRINT 'Created procedure portal.spFormSubmission_UpdateStatus';
GO

-- =============================================================================
-- 2. STORED PROCEDURE: portal.spFormCartPayment_GetBySubmission
--    Returns the most recent payment record for a submissionId.
--    Used by the portal form-wizard (view mode) to display payment details.
-- =============================================================================
IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[portal].[spFormCartPayment_GetBySubmission]') AND type = N'P')
    DROP PROCEDURE [portal].[spFormCartPayment_GetBySubmission];
GO

CREATE PROCEDURE [portal].[spFormCartPayment_GetBySubmission]
    @submissionId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        [paymentId],
        [submissionId],
        [formId],
        [gateway],
        [gatewaySessionId],
        [gatewayPaymentIntentId],
        [currency],
        [subtotalAmount],
        [taxAmount],
        [discountAmount],
        [totalAmount],
        [couponCode],
        [status],
        [paidAt],
        [createdAt],
        [updatedAt]
    FROM [portal].[FormCartPayments]
    WHERE [submissionId] = @submissionId
    ORDER BY [createdAt] DESC;
END
GO
PRINT 'Created procedure portal.spFormCartPayment_GetBySubmission';
GO

PRINT '=== 2026.04.06_rb.sql completed successfully ===';
GO
