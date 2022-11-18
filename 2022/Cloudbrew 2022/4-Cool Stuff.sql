USE DATABASE TEST;
USE SCHEMA dbo;

/********** Finding Previous Non-null Value **********/

CREATE OR REPLACE TABLE dbo.TestWindow
(ID INT IDENTITY(1,1) NOT NULL
,ColA INT NULL);

INSERT INTO dbo.TestWindow(ColA)
VALUES   (8)
        ,(NULL)
        ,(-10)
        ,(15)
        ,(NULL)
        ,(NULL)
        ,(NULL)
        ,(NULL)
        ,(3)
        ,(37);


SELECT *
FROM dbo.TestWindow;

SELECT
     ID
    ,ColA
    ,LAG(ColA) OVER (ORDER BY ID) previousnull
    ,LAG(ColA) IGNORE NULLS OVER (ORDER BY ID) previousnonnull
FROM dbo.TestWindow;

/********** GET_DDL **********/

SELECT GET_DDL('SCHEMA','STACKOVERFLOW.dbo');

/********** Query History **********/

USE ROLE accountadmin; -- default only role that has access
USE SCHEMA snowflake.account_usage;
SELECT *
FROM snowflake.account_usage.QUERY_HISTORY
ORDER BY START_TIME desc;

/********** ILIKE **********/

USE DATABASE TEST;
USE SCHEMA dbo;

CREATE OR REPLACE TABLE dbo.LikeTest AS
SELECT 'HelloWorld' AS MyString
UNION ALL
SELECT 'helloworld' AS MyString
UNION ALL
SELECT 'HELLOWORLD' AS MyString;

SELECT MyString
FROM dbo.LikeTest
WHERE MyString LIKE 'Hello%';

SELECT MyString
FROM dbo.LikeTest
WHERE MyString ILIKE 'Hello%';

/********** RATIO_TO_REPORT **********/
WITH CTE_SourceData AS
(
SELECT
     MONTH(p.POSTCREATIONDATE)  AS MonthNbr
    ,pt.POSTTYPEDESC
    ,COUNT(p.POSTID)            AS Cnt 
FROM STACKOVERFLOW.DBO.POSTS    p
JOIN STACKOVERFLOW.DBO.POSTTYPE pt ON p.POSTTYPEID = pt.POSTTYPEID
WHERE YEAR(p.POSTCREATIONDATE) = 2018
GROUP BY pt.POSTTYPEDESC,MonthNbr
)
SELECT
     MonthNbr
    ,PostTypeDesc
    ,Cnt
    ,RATIO_TO_REPORT(Cnt) OVER (PARTITION BY MonthNbr) AS PctOfTotal
FROM CTE_SourceData
ORDER BY MonthNbr, PctOfTotal DESC;

WITH CTE_SourceData AS
(
SELECT
     MONTH(p.POSTCREATIONDATE)  AS MonthNbr
    ,pt.POSTTYPEDESC
    ,COUNT(p.POSTID)            AS Cnt 
FROM STACKOVERFLOW.DBO.POSTS    p
JOIN STACKOVERFLOW.DBO.POSTTYPE pt ON p.POSTTYPEID = pt.POSTTYPEID
WHERE YEAR(p.POSTCREATIONDATE) = 2018
GROUP BY pt.POSTTYPEDESC,MonthNbr
)
SELECT
     MonthNbr
    ,PostTypeDesc
    ,Cnt
    ,Cnt / SUM(Cnt) OVER (PARTITION BY MonthNbr) AS PctOfTotal
FROM CTE_SourceData
ORDER BY MonthNbr, PctOfTotal DESC;

-- RESULT_SCAN
-- first run a query
SELECT MyString
FROM dbo.LikeTest
WHERE MyString ILIKE 'Hello%';

select 1;

select 2;

select * from table(result_scan(LAST_QUERY_ID(-3)));

-- [NOT] DISTINCT FROM
USE DATABASE TEST;
CREATE OR REPLACE TABLE dbo.NULLTest(someString STRING);
INSERT INTO dbo.NULLTest
SELECT 'Hello GroupBy!'
UNION ALL
SELECT NULL
UNION ALL
SELECT 'How you doing?';

SELECT * FROM dbo.NULLTest;
SELECT * FROM dbo.NULLTest WHERE someString <> NULL;
SELECT * FROM dbo.NULLTest WHERE someString = NULL;
SELECT * FROM dbo.NULLTest WHERE someString <> 'Hello GroupBy!';
SELECT * FROM dbo.NULLTest WHERE someString IS DISTINCT FROM 'Hello GroupBy!';

/********** ROW-PATTERN RECOGNITION **********/

CREATE OR REPLACE TABLE dbo.StockPrice(CompanyName VARCHAR(50), PriceDate date, Price int);

INSERT INTO dbo.StockPrice(CompanyName, PriceDate, Price)
VALUES
    ('A', '2021-08-01', 25),
    ('A', '2021-08-02', 31),
    ('A', '2021-08-03', 36),
    ('A', '2021-08-04', 37),
    ('A', '2021-08-05', 35),
    ('A', '2021-08-06', 32),
    ('A', '2021-08-07', 29),
    ('A', '2021-08-08', 22),
    ('A', '2021-08-09', 17),
    ('A', '2021-08-10', 15),
    ('A', '2021-08-11', 18),
    ('A', '2021-08-12', 26),
    ('A', '2021-08-13', 29),
    ('A', '2021-08-14', 33),
    ('A', '2021-08-15', 39),
    ('A', '2021-08-16', 42),
    ('A', '2021-08-17', 45),
    ('A', '2021-08-18', 44),
    ('A', '2021-08-19', 41),
    ('A', '2021-08-20', 40);
    
SELECT *
FROM dbo.StockPrice
MATCH_RECOGNIZE
(
    PARTITION BY CompanyName
    ORDER BY PriceDate
    MEASURES
         match_number()     AS match_number
        ,first(PriceDate)   AS start_date
        ,last(PriceDate)    AS end_date
        ,count(*)           AS rows_in_sequence
        ,count(B.*)         AS num_decreases
        ,count(C.*)         AS num_increases
        ,max(Price)         AS max_price
        ,min(Price)         AS min_price
    ONE ROW PER MATCH
    AFTER MATCH SKIP TO LAST C
    PATTERN(A B+ C+)
    DEFINE
         B as price < lag(Price)
        ,C as price > lag(Price)
)
ORDER BY CompanyName, match_number;