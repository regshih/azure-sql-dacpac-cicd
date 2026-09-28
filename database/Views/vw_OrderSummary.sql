CREATE VIEW [dbo].[vw_OrderSummary]
AS
SELECT
    o.[OrderId],
    o.[OrderDate],
    o.[Status],
    c.[CustomerId],
    c.[Email] AS [CustomerEmail],
    c.[DisplayName] AS [CustomerName],
    SUM(CONVERT(DECIMAL(19, 4), oi.[Quantity]) * oi.[UnitPrice]) AS [OrderTotal],
    SUM(oi.[Quantity]) AS [TotalUnits]
FROM [dbo].[Orders] AS o
INNER JOIN [dbo].[Customers] AS c ON o.[CustomerId] = c.[CustomerId]
INNER JOIN [dbo].[OrderItems] AS oi ON o.[OrderId] = oi.[OrderId]
GROUP BY o.[OrderId], o.[OrderDate], o.[Status], c.[CustomerId], c.[Email], c.[DisplayName];
