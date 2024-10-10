/* Set Up */

DROP TABLE IF EXISTS dbo.[Server];
CREATE TABLE dbo.[Server]
    (ID         INT IDENTITY(1,1) NOT NULL
    ,ServerName VARCHAR(50) NOT NULL
    ,DayOnline  DATE NOT NULL);
 
INSERT INTO dbo.[Server]
(
     [ServerName]
    ,DayOnline
)
VALUES
     ('MyServer','2024-05-01')
    ,('MyServer','2024-05-02')
    ,('MyServer','2024-05-03')
    ,('MyServer','2024-05-04')
    ,('MyServer','2024-05-05')
    ,('MyServer','2024-05-07')
    ,('MyServer','2024-05-08')
    ,('MyServer','2024-05-09')
    ,('MyServer','2024-05-15')
    ,('MyServer','2024-05-16')
    ,('MyServer','2024-05-17')
    ,('MyServer','2024-05-19')
    ,('MyServer','2024-05-20');

SELECT * FROM dbo.[Server];

/* Gaps */

WITH cte_lead AS
(
    SELECT
         [current] = DayOnline
        ,[next]    = LEAD(DayOnline) OVER (ORDER BY DayOnline)
    FROM dbo.[Server]
)
SELECT
     gapStart = DATEADD(DAY, 1, [current])
    ,gapEnd   = DATEADD(DAY,-1, [next])
    ,gapWidth = DATEDIFF(DAY, [current], DATEADD(DAY,-1, [next]))
FROM cte_lead
WHERE DATEDIFF(DAY, [current], [next]) > 1;

/* Islands */
WITH cte_groups AS
(
    SELECT
         DayOnline
        ,[Group] = DATEADD(DAY, -1 * DENSE_RANK() OVER
                                (PARTITION BY ServerName
                                 ORDER BY DayOnline)
                           , DayOnline)
    FROM dbo.[Server]
)
SELECT
     StartDate = MIN(DayOnline)
    ,EndDate   = MAX(DayOnline)
FROM cte_groups
GROUP BY [Group];