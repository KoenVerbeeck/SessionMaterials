-- 3. Tally Tables

-- 1. Generate Tally Table
WITH T0 AS (SELECT N	 FROM (VALUES (1),(1)) AS tmp(N))
	,T1 AS (SELECT N = 1 FROM T0 AS a CROSS JOIN T0 AS b)
	,T2 AS (SELECT N = 1 FROM T1 AS a CROSS JOIN T1 AS b)
	,T3 AS (SELECT N = 1 FROM T2 AS A CROSS JOIN T2 AS B)
	,T4 AS (SELECT N = 1 FROM T3 AS a CROSS JOIN T3 AS b)
SELECT *
FROM T3;

-- 2. Numbers table
WITH T0 AS (SELECT N	 FROM (VALUES (1),(1)) AS tmp(N))
	,T1 AS (SELECT N = 1 FROM T0 AS a CROSS JOIN T0 AS b)
	,T2 AS (SELECT N = 1 FROM T1 AS a CROSS JOIN T1 AS b)
	,T3 AS (SELECT N = 1 FROM T2 AS a CROSS JOIN T2 AS b)
	,T4 AS (SELECT N = 1 FROM T3 AS a CROSS JOIN T3 AS b)
SELECT RID = ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
FROM T4
ORDER BY RID;

-- 3. Date table
WITH T0 AS (SELECT N	 FROM (VALUES (1),(1)) AS tmp(N))
	,T1 AS (SELECT N = 1 FROM T0 AS a CROSS JOIN T0 AS b)
	,T2 AS (SELECT N = 1 FROM T1 AS a CROSS JOIN T1 AS b)
	,T3 AS (SELECT N = 1 FROM T2 AS a CROSS JOIN T2 AS b)
	,T4 AS (SELECT N = 1 FROM T3 AS a CROSS JOIN T3 AS b)
SELECT DATEADD(DAY,ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) -1,'2000-01-01')
FROM T4;

-- 4. Generate random data
DROP TABLE IF EXISTS [tempdb]..#Transactions;

WITH T0 AS (SELECT N	 FROM (VALUES (1),(1)) AS tmp(N))
	,T1 AS (SELECT N = 1 FROM T0 AS a CROSS JOIN T0 AS b)
	,T2 AS (SELECT N = 1 FROM T1 AS a CROSS JOIN T1 AS b)
	,T3 AS (SELECT N = 1 FROM T2 AS a CROSS JOIN T2 AS b)
	,T4 AS (SELECT N = 1 FROM T3 AS a CROSS JOIN T3 AS b)
	,T5 AS (SELECT N = 1 FROM T4 AS a CROSS JOIN T4 AS b) -- over 4 billion rows
SELECT
	 TransactionID		= ROW_NUMBER() OVER (ORDER BY NEWID())
	,TransactionAmount	= RAND(N) * 100000 - 30000
INTO #Transactions
FROM
	(
	SELECT TOP 60000
		 N = ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
	FROM T5
	) tmp
ORDER BY TransactionID;

SELECT * FROM [#Transactions];

-- 5. Explode Table
DROP TABLE IF EXISTS [tempdb]..#Contractors;
CREATE TABLE #Contractors
	(ID INT NOT NULL
	,ContractorName VARCHAR(100) NOT NULL
	,ProjectName VARCHAR(100) NOT NULL
	,StartDate DATE NOT NULL
	,EndDate DATE NULL);

INSERT INTO #Contractors VALUES(1,'Koen','Project X','2015-01-05','2015-01-21');

DECLARE @StartDate DATE = '2015-01-01';

WITH T0 AS (SELECT N	 FROM (VALUES (1),(1)) AS tmp(N))
	,T1 AS (SELECT N = 1 FROM T0 AS a CROSS JOIN T0 AS b)
	,T2 AS (SELECT N = 1 FROM T1 AS a CROSS JOIN T1 AS b)
	,T3 AS (SELECT N = 1 FROM T2 AS a CROSS JOIN T2 AS b)
	,T4 AS (SELECT N = 1 FROM T3 AS a CROSS JOIN T3 AS b)
	,T5 AS (SELECT N = 1 FROM T4 AS a CROSS JOIN T4 AS b) -- over 4 billion rows
	,Tally AS (SELECT N = ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM T5)
	,DateList AS
(
	SELECT TOP 365
		SequentialDate = DATEADD(DAY,N-1,@StartDate)
	FROM Tally
)
SELECT
	 c.ContractorName
	,c.ProjectName
	,ActiveDate = d.SequentialDate
FROM DateList		d
JOIN #Contractors	c ON	d.SequentialDate >= c.StartDate
						AND	d.SequentialDate <= c.EndDate
						AND c.EndDate IS NOT NULL; -- only take closed periods

-- 6. Looping through a string
DECLARE @myString VARCHAR(100) = 'Hello dataminds connect attendees!';

WITH T0 AS (SELECT N	 FROM (VALUES (1),(1)) AS tmp(N))
	,T1 AS (SELECT N = 1 FROM T0 AS a CROSS JOIN T0 AS b)
	,T2 AS (SELECT N = 1 FROM T1 AS a CROSS JOIN T1 AS b)
	,T3 AS (SELECT N = 1 FROM T2 AS a CROSS JOIN T2 AS b)
	,T4 AS (SELECT N = 1 FROM T3 AS a CROSS JOIN T3 AS b)
    ,Iterator AS
        (
            SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
            FROM T4
        )
SELECT
    SUBSTRING(@myString,i,1)
FROM Iterator
WHERE i <= LEN(@myString);


-- BE SURE TO CHECK OUT GENERATE_SERIES IN SQL SERVER 2022!