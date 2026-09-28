CREATE PROCEDURE [dbo].[usp_GetCustomerOrders]
    @CustomerId INT,
    @FromDate DATETIME2(3) = NULL,
    @ToDate DATETIME2(3) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        [OrderId],
        [OrderDate],
        [Status],
        [CustomerId],
        [CustomerEmail],
        [CustomerName],
        [OrderTotal],
        [TotalUnits]
    FROM [dbo].[vw_OrderSummary]
    WHERE
        [CustomerId] = @CustomerId
        AND (@FromDate IS NULL OR [OrderDate] >= @FromDate)
        AND (@ToDate IS NULL OR [OrderDate] < @ToDate)
    ORDER BY [OrderDate] DESC;
END;
