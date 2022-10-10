--5.  Covering index demo */
USE [AdventureWorksDW2019];

SET STATISTICS IO ON;

DROP INDEX IF EXISTS IX_InternetSales_OrderDate_ProductKey ON dbo.[FactInternetSales];

SELECT f.OrderDateKey, SUM([f].[SalesAmount])
FROM [dbo].[FactInternetSales]  f
JOIN [dbo].[DimProduct]         p ON [p].[ProductKey] = [f].[ProductKey]
WHERE   f.OrderDateKey          >= 20110101
    AND f.OrderDateKey          <= 20110131
    AND p.[EnglishProductName]  = 'Road-150 Red, 62'
GROUP BY f.OrderDateKey;

-- Attempt #1
CREATE NONCLUSTERED INDEX IX_InternetSales_OrderDate_ProductKey
ON [dbo].[FactInternetSales] ([OrderDateKey], [ProductKey]);

-- Attempt #2
DROP INDEX IF EXISTS IX_InternetSales_OrderDate_ProductKey ON dbo.[FactInternetSales];

CREATE NONCLUSTERED INDEX IX_InternetSales_OrderDate_ProductKey
ON [dbo].[FactInternetSales] ([OrderDateKey], [ProductKey])
INCLUDE([SalesAmount]);

SET STATISTICS IO OFF;