USE Test;

/* Window Functions Performance Tuning */
-- sample data
DROP TABLE IF EXISTS dbo.Inventory;

WITH T0 AS (SELECT N	 FROM (VALUES (1),(1)) AS tmp(N))
    ,T1 AS (SELECT N = 1 FROM T0 AS a CROSS JOIN T0 AS b)
    ,T2 AS (SELECT N = 1 FROM T1 AS a CROSS JOIN T1 AS b)
    ,T3 AS (SELECT N = 1 FROM T2 AS a CROSS JOIN T2 AS b)
    ,T4 AS (SELECT N = 1 FROM T3 AS a CROSS JOIN T3 AS b)
    ,T5 AS (SELECT N = 1 FROM T4 AS a CROSS JOIN T4 AS b) -- over 4 billion rows
SELECT
     InventoryID        = ROW_NUMBER() OVER (ORDER BY NEWID())
    ,InventoryChange    = RAND(N) * 100000 - 30000
INTO dbo.Inventory
FROM
    (
    SELECT TOP 100000
            N = ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
    FROM T5
    ) tmp
ORDER BY InventoryID;

DROP TABLE IF EXISTS dbo.Warehouses;

WITH T0 AS (SELECT N	 FROM (VALUES (1),(1)) AS tmp(N))
	,T1 AS (SELECT N = 1 FROM T0 AS a CROSS JOIN T0 AS b)
	,T2 AS (SELECT N = 1 FROM T1 AS a CROSS JOIN T1 AS b)
	,T3 AS (SELECT N = 1 FROM T2 AS a CROSS JOIN T2 AS b)
SELECT TOP 100
	Warehouse = CONCAT('Warehouse ',ROW_NUMBER() OVER (ORDER BY (SELECT NULL)))
INTO dbo.Warehouses
FROM T3;

DROP TABLE IF EXISTS dbo.InventoryChanges;
SELECT
	 w.[Warehouse]
	,i.[InventoryID]
	,i.[InventoryChange]
    ,InsertDate = GETDATE()
    ,ModifiedBy = 'Koen Verbeeck'
    ,SomeExtraColumnm = NEWID()
INTO dbo.InventoryChanges
FROM dbo.Warehouses     w
CROSS JOIN dbo.Inventory  i;

SET STATISTICS IO, TIME ON; -- enable actual execution plan!!!
GO

-- Query without indexes
-- (about 36 seconds)
SELECT
     Warehouse
    ,InventoryChange
    ,Balance = SUM(InventoryChange) OVER (PARTITION BY Warehouse
                                          ORDER BY InventoryID
                                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                                         )
FROM dbo.InventoryChanges
ORDER BY Warehouse,InventoryID;

-- Create index
DROP INDEX IF EXISTS [NCI_InventoryChanges] ON dbo.InventoryChanges;
CREATE NONCLUSTERED INDEX [NCI_InventoryChanges]
ON [dbo].[InventoryChanges]
(
     [Warehouse] ASC
    ,[InventoryID] ASC
)
INCLUDE ([InventoryChange]);
