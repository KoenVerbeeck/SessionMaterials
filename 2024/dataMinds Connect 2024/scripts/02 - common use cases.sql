/* 1 - Median */
SELECT DISTINCT
     DepartmentName
    ,MedianRate = PERCENTILE_CONT(0.5)
                    WITHIN GROUP(ORDER BY BaseRate)
                    OVER (PARTITION BY DepartmentName)
FROM AdventureWorksDW2019.dbo.DimEmployee
ORDER BY MedianRate DESC;

/* 2 - RANGE vs ROWS */
DROP TABLE IF EXISTS Test.dbo.TestRangeRows;
CREATE TABLE Test.dbo.TestRangeRows
    (ID INT IDENTITY(1,1) PRIMARY KEY NOT NULL
    ,[Group] CHAR(1) NOT NULL
    ,[Value] INT NOT NULL);
 
INSERT INTO Test.dbo.TestRangeRows([Group],[Value])
VALUES   ('A',1)
        ,('A',1)
        ,('A',1)
        ,('A',1)
        ,('B',1)
        ,('B',1)
        ,('B',1)
        ,('B',1)
        ,('B',1);

SELECT
     [Group]
    ,[Value]
    ,RowsTest   = SUM([Value]) OVER (PARTITION BY [Group] ORDER BY [Value]
                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
    ,RangeTest  = SUM([Value]) OVER (PARTITION BY [Group] ORDER BY [Value]
                     RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM Test.dbo.TestRangeRows;

/* 3 - Deal with Duplicate Rows */
DROP TABLE IF EXISTS Test.dbo.EmployeeDuplicate;
CREATE TABLE Test.dbo.EmployeeDuplicate
(
     ID             INT IDENTITY(1,1) NOT NULL
    ,EmployeeKey    INT NOT NULL
    ,EmployeeName   VARCHAR(20) NOT NULL
    ,InsertDate     DATE NOT NULL
);

INSERT INTO Test.dbo.EmployeeDuplicate
(
    EmployeeKey
    ,EmployeeName
    ,InsertDate
)
SELECT 1, 'Bob', '2018-05-01'
UNION ALL
SELECT 2, 'Alice', '2017-12-31'
UNION ALL
SELECT 3, 'Trudy', '2018-04-21'
UNION ALL
SELECT 1, 'Bob', '2018-05-09';

WITH cte_src AS
(
    SELECT
         ID
        ,EmployeeKey
        ,EmployeeName
        ,InsertDate
        ,RID = ROW_NUMBER() OVER (PARTITION BY EmployeeKey ORDER BY InsertDate)
    FROM Test.dbo.EmployeeDuplicate
)
DELETE FROM Test.dbo.EmployeeDuplicate
FROM Test.dbo.EmployeeDuplicate ed
JOIN cte_src                    c ON ed.ID = c.ID
WHERE c.RID <> 1;

/* 4 - Tally Table */
WITH T0 AS (SELECT N FROM (VALUES (1),(1)) AS tmp(N))
    ,T1 AS (SELECT N = 1 FROM T0 AS a CROSS JOIN T0 AS b)
    ,T2 AS (SELECT N = 1 FROM T1 AS a CROSS JOIN T1 AS b)
    ,T3 AS (SELECT N = 1 FROM T2 AS a CROSS JOIN T2 AS b)
    ,T4 AS (SELECT N = 1 FROM T3 AS a CROSS JOIN T3 AS b)
SELECT MyDate = DATEADD(DAY,ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) -1,'2024-01-01')
FROM T4;
--> can be replaced with GENERATE_SERIES in later versions

/* 5 - Inspect other rows */
WITH CTE_PY AS
(
    SELECT
         [Year]                       = YEAR(OrderDate)
        ,[Sales Amount]               = SUM(SalesAmount)
        ,[Sales Amount Previous Year] = LAG(SUM(SalesAmount)) OVER (ORDER BY YEAR(OrderDate))
    FROM AdventureWorksDW2019.dbo.FactResellerSales
    GROUP BY YEAR(OrderDate)
)
SELECT
     CTE_PY.[Year]
    ,CTE_PY.[Sales Amount]
    ,CTE_PY.[Sales Amount Previous Year]
    ,[YoY Growth] = 100.0 * (CTE_PY.[Sales Amount] - CTE_PY.[Sales Amount Previous Year])
                    / CTE_PY.[Sales Amount Previous Year]
FROM CTE_PY
ORDER BY CTE_PY.[Year];