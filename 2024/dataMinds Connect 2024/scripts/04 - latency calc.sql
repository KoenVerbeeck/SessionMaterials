DROP TABLE IF EXISTS #allocations;
DROP TABLE IF EXISTS #headcount;
DROP TABLE IF EXISTS #dates;
DROP TABLE IF EXISTS #employees;
DROP TABLE IF EXISTS #starters;
DROP TABLE IF EXISTS #gaps_islands;
DROP TABLE IF EXISTS #LatencyStarters;
DROP TABLE IF EXISTS #LatencyBench;
DROP TABLE IF EXISTS #LatencyZero;
DROP TABLE IF EXISTS #possible_zeros;

/* variables */
/*
DECLARE @LATENCY_MIN_DAYS       INT = 15;
DECLARE @LATENCY_PERC           NUMERIC(3,2) = 0.60;
DECLARE @LATENCY_WINDOW_MONTHS  INT = 1;
*/

/* insert sample data */
CREATE TABLE #allocations
(
     project         VARCHAR(50)
    ,employeeId      VARCHAR(50)
    ,startDate       DATETIME
    ,expectedEndDate DATETIME
    ,weeklyCapacity  DECIMAL(18, 3)
);

INSERT INTO #allocations (project, [employeeId], [startDate], [expectedEndDate], [weeklyCapacity])
VALUES
('A', '01', '2022-07-04T00:00:00', '2022-08-31T00:00:00', 0.100 ),
('B', '01', '2022-08-01T00:00:00', '2022-09-03T00:00:00', 0.400 ),
('C', '01', '2022-08-08T02:00:00', '2022-10-30T01:00:00', 1.000 ),
('D', '01', '2022-10-31T00:00:00', '2022-11-04T00:00:00', 0.600 ),
('E', '01', '2023-01-01T02:00:00', '2024-03-31T03:00:00', 0.200 ),
('F', '01', '2023-02-20T06:00:00', '2023-12-31T11:00:00', 0.600 ),
('G', '01', '2023-06-05T00:00:00', '2023-07-09T00:00:00', 0.200 ),
('H', '01', '2023-09-04T00:00:00', '2023-10-29T00:00:00', 0.100 ),
('I', '01', '2024-01-11T04:00:00', '2024-01-31T04:00:00', 0.600 ),
('J', '01', '2024-02-05T00:00:00', '2024-02-29T00:00:00', 0.200 ),
('K', '01', '2024-02-12T02:00:00', '2024-06-30T03:00:00', 0.200 ),
('L', '01', '2024-04-15T05:00:00', '2024-12-29T06:00:00', 0.400 ),
('M', '01', '2024-05-13T02:00:00', '2024-09-29T02:00:00', 0.400 ),
('E', '01', '2024-05-27T00:00:00', '2024-09-29T00:00:00', 0.200 ),
('N', '02', '2024-07-27T00:00:00', '2025-03-30T00:00:00', 1.000 ),
('O', '03', '2024-01-01T00:00:00', '2024-05-31T00:00:00', 1.000 ),
('P', '03', '2024-06-01T00:00:00', '2024-12-31T00:00:00', 1.000 );
;

SELECT * FROM #allocations;

/* get a filtered down version of the date dim to improve performance */
/* Normally there'd be a date dimension you can use. Use the script "create data table.sql" to create a small date table. */
SELECT d.SK_Date, d.IsWorkDay
/* we're not filtering on work days yet, as we need a continuous date range for the islands calc */
INTO #dates
FROM Test.dbo.myDates d
WHERE   d.SK_Date  <= CONVERT(DATE,(DATEADD(MONTH,1/*@LATENCY_WINDOW_MONTHS*/,GETDATE())))
    AND d.SK_Date  >= '2022-01-01'; -- data starts in 2022

--SELECT * FROM #dates

/* get all employee IDs that are working or have worked for the company */
/* sample query:
SELECT DISTINCT EmployeeID
INTO #employees
FROM dbo.Fact_EmployeeHeadCount     eh
JOIN dbo.Dim_EmployeeProfile        f ON eh.SK_EmployeeProfile      = f.SK_EmployeeProfile
JOIN dbo.Dim_EmployeeContractType   c ON eh.SK_EmployeeContractType = c.SK_EmployeeContractType
WHERE   1 = 1
    AND eh.SK_Date                     >= '2022-01-01'
    AND f.EmployeeProfile_IsConsultant  = 'Yes' -- only billable/consultant profiles
    AND c.EmployeeContractType         <> 'STC' -- no short term contractors
*/

/* Dummy employeeID */
SELECT EmployeeID = '01'
INTO #employees
UNION ALL
SELECT EmployeeID = '02'
UNION ALL
SELECT EmployeeID = '03';

/*  Get all starting employees from the HR fact table.
Sample Query:

SELECT
     SK_StartDate = hr.SK_Date
    ,hr.EmployeeID
INTO #starters
FROM dbo.Fact_HR hr
WHERE   hr.Type = 'Start'
    /* we only want data for recent starters */
    AND hr.SK_Date >= '2022-01-01'
    AND EXISTS (SELECT 1 FROM #employees e WHERE hr.EmployeeID = e.EmployeeID); -- apply all the employee filters (so only consultants etc)
*/

SELECT SK_StartDate = CONVERT(DATE,'2024-07-01'), EmployeeID = '02'
INTO #starters
UNION ALL
SELECT SK_StartDate = CONVERT(DATE,'2024-01-01'), EmployeeID = '03';

/*  Generate a headcount table with one row for each day an employee is working.
    For an employee, the first date in the headcount table is their starting date.
    The end date is 2024-12-31 for everyone.
    Everyone works fulltime.
*/
WITH cte_emps AS
(
    SELECT
         e.EmployeeID
        ,SK_StartDate       = ISNULL(s.SK_StartDate,'2022-01-01')
        ,SK_EndDate         = CONVERT(DATE,'2024-12-31')
        ,NbrOfDaysPerWeek   = 5 -- fulltime
    FROM #employees e
    LEFT JOIN #starters s ON e.EmployeeID = s.EmployeeID
)
/* generate tally table */
    ,T0 AS (SELECT N	 FROM (VALUES (1),(1)) AS tmp(N))
	,T1 AS (SELECT N = 1 FROM T0 AS a CROSS JOIN T0 AS b)
	,T2 AS (SELECT N = 1 FROM T1 AS a CROSS JOIN T1 AS b)
	,T3 AS (SELECT N = 1 FROM T2 AS a CROSS JOIN T2 AS b)
	,T4 AS (SELECT N = 1 FROM T3 AS a CROSS JOIN T3 AS b)
    ,dates AS
(
    SELECT SK_Date = DATEADD(DAY,ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) -1,'2022-01-01')
    FROM T4
)
SELECT d.SK_Date, e.EmployeeID, e.NbrOfDaysPerWeek
INTO #headcount
FROM cte_emps       e
CROSS JOIN dates    d
WHERE   e.SK_StartDate  <= d.SK_Date
    AND e.SK_EndDate    >= d.SK_Date;

/*
    for each employee, get their allocation data and mark their "significant" work days
*/
WITH cte_allocdays AS
(
    SELECT
         EmployeeID = a.employeeId
        ,d.SK_Date
        ,NbrOfDaysPerWeek_Allocated = SUM(weeklyCapacity * 5)
    FROM #allocations a
    JOIN #dates         d ON    d.SK_Date >= CONVERT(DATE,a.startDate)
                            AND d.SK_Date <= ISNULL(a.expectedEndDate,'9999-12-31')
    GROUP BY a.employeeId
            ,d.SK_Date
)
--SELECT * FROM cte_allocdays
--> make sure we have a continuous timeline for each employee
,   cte_all_dates_employees AS
(
    SELECT
         d.SK_Date
        ,e.EmployeeID
    FROM #dates d
    CROSS JOIN #employees e
)
--SELECT * FROM cte_all_dates_employees
,   cte_signalloc AS
(
    SELECT
         d.EmployeeID
        ,d.SK_Date
        ,NbrOfDaysPerWeek_Allocated = ISNULL(a.NbrOfDaysPerWeek_Allocated,0.0)
        ,h.NbrOfDaysPerWeek
        -- a consultant has a significant allocation if the number of days allocated is 60% (configured by parameter) or higher of the work schedule
        ,significantAllocated = IIF(ISNULL(a.NbrOfDaysPerWeek_Allocated,0.0) >= h.NbrOfDaysPerWeek * 0.6/*@LATENCY_PERC*/,1,0)
    FROM cte_all_dates_employees    d
    LEFT JOIN cte_allocdays         a ON    d.SK_Date       = a.SK_Date
                                        AND d.EmployeeID    = a.EmployeeID
    --> if an employee has left, the days after the end date will be filtered out by the headcount table
    --> if an employee has started later in the year, the dates will start from their starting day
    JOIN #headcount                 h ON    d.EmployeeID    = h.EmployeeID
                                        AND d.SK_Date       = h.SK_Date
)
SELECT
     EmployeeID
    ,SK_Date
    ,significantAllocated
INTO #gaps_islands
FROM cte_signalloc;

SELECT * FROM #gaps_islands
ORDER BY SK_Date,EmployeeID;

--DECLARE @LATENCY_MIN_DAYS       INT = 15;
/* set allocation series that are not long enough to not significant allocations */
WITH cte_significant_alloc AS
(
    SELECT
         EmployeeID
        ,SK_Date
        --,significantAllocated   
        -- island problem, see Itzik Ben-Gan
        ,grp = DATEADD(DAY,-1* DENSE_RANK() OVER (PARTITION BY EmployeeID ORDER BY SK_Date), SK_Date)
    FROM #gaps_islands
    WHERE significantAllocated = 1
)
,   cte_ranges AS
(
    SELECT
         EmployeeID
        ,StartRange     = MIN(SK_Date)
        ,EndRange       = MAX(SK_Date)
    FROM cte_significant_alloc
    GROUP BY EmployeeID, grp
)
--SELECT * FROM cte_ranges
,   cte_short_durations AS -- number of working days in the island
(
    SELECT
         r.EmployeeID
        ,r.StartRange
        ,r.EndRange
        ,RangeDuration = COUNT(1)
    FROM cte_ranges r
    JOIN #dates d ON    d.SK_Date >= r.StartRange
                    AND d.SK_Date <= r.EndRange
    WHERE   1 = 1
        AND d.IsWorkDay = 'yes'
    GROUP BY r.EmployeeID, r.StartRange, r.EndRange
    HAVING COUNT(1) < 15 /*@LATENCY_MIN_DAYS*/ -- default value is 15 days
)
--SELECT * FROM cte_short_durations
UPDATE g
SET significantAllocated = 0
--SELECT g.*
FROM #gaps_islands g
JOIN cte_short_durations s ON g.EmployeeID = s.EmployeeID
                            AND g.SK_Date >= s.StartRange
                            AND g.SK_Date <= s.EndRange;

/* calculate starter latency */
WITH cte_significant_alloc AS
(
    SELECT
         EmployeeID
        ,SK_Date
        -- recalculate islands, since we "sank" the islands that were too small
        ,grp = DATEADD(DAY,-1* DENSE_RANK() OVER (PARTITION BY EmployeeID ORDER BY SK_Date), SK_Date)
    FROM #gaps_islands
    WHERE significantAllocated = 1
        AND EmployeeID IN (SELECT EmployeeID FROM #starters)
)
,   cte_ranges AS
(
    SELECT
         EmployeeID
        ,StartRange     = MIN(SK_Date)
        ,EndRange       = MAX(SK_Date)
    FROM cte_significant_alloc
    GROUP BY EmployeeID, grp
)
--SELECT * FROM cte_ranges
,   cte_latency_end AS
(
    SELECT
         s.EmployeeID
        ,s.SK_StartDate
        ,tmp.StartRange
        ,LatencyType    = 'Hires'
        --> if StartRange is NULL, no (long-term) projects have been allocated yet
        -- we choose the date of today to calculate latency. For starters who start after today, they will be filtered out in the next step.
        ,LatencyEndDate = CONVERT(DATE,ISNULL(tmp.StartRange,GETDATE()))
    FROM #starters s
    LEFT JOIN
        ( --> retrieve the first allocation (and we've already filtered out allocations that were too short)
            SELECT *, rid = ROW_NUMBER() OVER (PARTITION BY EmployeeID ORDER BY StartRange)
            FROM cte_ranges
        ) tmp ON tmp.EmployeeID = s.EmployeeID AND tmp.rid = 1
)
--SELECT * FROM cte_latency_end
,   cte_latency AS
(
    SELECT
         l.EmployeeID
        ,l.SK_StartDate
        ,l.LatencyType
        ,Latency = COUNT(1) - 1 
    FROM cte_latency_end    l
    JOIN #dates             d ON    d.SK_Date >= l.SK_StartDate
                                -- we include the first date of the significant period for the edge case where someone starts on their first day
                                AND d.SK_Date <= l.LatencyEndDate 
    WHERE d.IsWorkDay = 'yes'
    GROUP BY l.EmployeeID
            ,l.SK_StartDate
            ,l.LatencyType
)
--SELECT * FROM cte_latency
SELECT
     SK_Date = l.SK_StartDate
    ,l.EmployeeID
    ,l.LatencyType
    ,l.Latency
INTO #LatencyStarters
FROM cte_latency    l
ORDER BY l.SK_StartDate;

SELECT * FROM #LatencyStarters;

/* calculate bench latency */
WITH cte_bench AS
(
    SELECT
         EmployeeID
        ,SK_Date
        -- this time we're calculating the duration of the benches
        ,grp = DATEADD(DAY,-1* DENSE_RANK() OVER (PARTITION BY EmployeeID ORDER BY SK_Date), SK_Date)
    FROM #gaps_islands
    WHERE significantAllocated = 0
)
,   cte_ranges AS
(
    SELECT
         EmployeeID
        ,StartRange     = MIN(SK_Date)
        ,EndRange       = MAX(SK_Date)
    FROM cte_bench
    GROUP BY EmployeeID, grp
)
--SELECT * FROM cte_ranges
,   cte_durations AS -- number of working days in the gap
(
    SELECT
         r.EmployeeID
        ,r.StartRange
        ,r.EndRange
        ,LatencyType    = 'Benchers'
        ,Latency        = COUNT(1)
    FROM cte_ranges r
    JOIN #dates d ON    d.SK_Date >= r.StartRange
                    AND d.SK_Date <= r.EndRange
    WHERE d.IsWorkDay = 'yes'
    GROUP BY r.EmployeeID, r.StartRange, r.EndRange
)
--SELECT * FROM cte_durations
SELECT
     SK_Date = l.StartRange
    ,l.EmployeeID
    ,l.LatencyType
    ,l.Latency
INTO #LatencyBench
FROM cte_durations              l
--> filter out the latency of the starters since we've already covered that one
WHERE NOT EXISTS (SELECT 1 FROM #LatencyStarters s WHERE l.EmployeeID = s.EmployeeID AND l.StartRange = s.SK_Date);

SELECT * FROM #LatencyBench;

--DECLARE @LATENCY_PERC NUMERIC(3,2) = 0.60;
/* calculate zero latency
    these happen when a consultant goes from one significant allocation to another, without any bench
    most likely contract extensions?
*/
WITH cte_islands AS
(
    SELECT
         EmployeeID
        ,SK_Date
        -- island problem, see Itzik Ben-Gan
        ,grp = DATEADD(DAY,-1* DENSE_RANK() OVER (PARTITION BY EmployeeID ORDER BY SK_Date), SK_Date)
    FROM #gaps_islands
    WHERE significantAllocated = 1
)
,   cte_ranges AS
(
    SELECT
         EmployeeID
        ,StartRange     = MIN(SK_Date)
        ,EndRange       = MAX(SK_Date)
    FROM cte_islands
    GROUP BY EmployeeID, grp
)
--SELECT * FROM cte_ranges
-- we're retrieving all significant allocations for a consultant
-- in the next step, we're looking for allocations that start in the middle of a significant range
,   cte_alloc AS
(
    SELECT
         a.project
        ,EmployeeID                 = a.employeeId
        ,SK_StartDate               = CONVERT(DATE,a.startDate)
        ,SK_EndDate                 = CONVERT(DATE,a.expectedEndDate)
        ,NbrOfDaysPerWeek_Allocated = weeklyCapacity * 5
        ,h.NbrOfDaysPerWeek
        --> the one allocation in itself is significant
        ,significantAllocated       = IIF((weeklyCapacity * 5) >= h.NbrOfDaysPerWeek * 0.6 /*@LATENCY_PERC*/,1,0)
    FROM #allocations   a
    JOIN #headcount     h   ON  a.employeeId    = h.EmployeeID
                            AND h.SK_Date       = CONVERT(DATE,a.startDate)
)
SELECT
     r.EmployeeID
    ,r.StartRange
    ,r.EndRange
    ,a.SK_StartDate
    ,a.SK_EndDate
    ,a.project
    ,a.NbrOfDaysPerWeek_Allocated
    ,a.NbrOfDaysPerWeek
INTO #possible_zeros
FROM cte_ranges r
JOIN cte_alloc  a ON    r.EmployeeID            = a.employeeId
                    AND a.significantAllocated  = 1 --> only significant allocations
                    --> the allocation starts in the middle of a range
                    AND a.SK_StartDate          > r.StartRange
                    AND a.SK_StartDate          < r.EndRange;

SELECT *
FROM #possible_zeros
ORDER BY EmployeeID;

/* now we need to verify if the period before the allocation is also significant,
    meaning we have a switch from one significant allocation to another.
    We also check the right side (after the start of the allocation),  because there might be reasons why the allocation stops
    (for example the consultant leaving AE), but the source data is not up to date.
*/
WITH cte_check_ranges AS
(
    SELECT
         tmp.EmployeeID
        ,tmp.SK_StartDate
        ,allocated_days_left    = MAX(allocated_days_left)
        ,allocated_days_right   = MAX(allocated_days_right)
    FROM (
        SELECT
             z.EmployeeID
            ,z.SK_StartDate
            ,allocated_days_left    = COUNT(1)
            ,allocated_days_right   = NULL
        FROM #possible_zeros    z
        JOIN #dates             d ON    d.SK_Date >= z.StartRange
                                    AND d.SK_Date  < z.SK_StartDate
        WHERE d.IsWorkDay = 'yes'
        GROUP BY z.EmployeeID, z.SK_StartDate
        UNION ALL
        SELECT
             z.EmployeeID
            ,z.SK_StartDate
            ,allocated_days_left   = NULL
            ,allocated_days_right = COUNT(1)
        FROM #possible_zeros    z
        JOIN #dates             d ON    d.SK_Date >= z.SK_StartDate
                                    AND d.SK_Date <= z.SK_EndDate
        WHERE d.IsWorkDay = 'yes'
        GROUP BY z.EmployeeID, z.SK_StartDate
    ) tmp
    GROUP BY tmp.EmployeeID, tmp.SK_StartDate
)
SELECT
     SK_Date = l.SK_StartDate
    ,l.EmployeeID
    ,LatencyType    = '0-Latency'
    ,Latency        = 0 --> this should be used as a count, but 0 is set for when people accidentally use it in an aggregate
INTO #LatencyZero
FROM cte_check_ranges l
WHERE l.allocated_days_left >= 15 /*@LATENCY_MIN_DAYS*/ AND l.allocated_days_right >= 15 /*@LATENCY_MIN_DAYS*/;

SELECT * FROM #LatencyZero

SELECT
     SK_Date
    ,EmployeeID
    ,LatencyType
    ,Latency
FROM #LatencyStarters
UNION ALL
SELECT
     SK_Date
    ,EmployeeID
    ,LatencyType
    ,Latency
FROM #LatencyBench
UNION ALL
SELECT
    SK_Date
    ,EmployeeID
    ,LatencyType
    ,Latency
FROM #LatencyZero
ORDER BY SK_Date, EmployeeID;

DROP TABLE IF EXISTS #allocations;
DROP TABLE IF EXISTS #headcount;
DROP TABLE IF EXISTS #dates;
DROP TABLE IF EXISTS #employees;
DROP TABLE IF EXISTS #starters;
DROP TABLE IF EXISTS #gaps_islands;
DROP TABLE IF EXISTS #LatencyStarters;
DROP TABLE IF EXISTS #LatencyBench;
DROP TABLE IF EXISTS #LatencyZero;
DROP TABLE IF EXISTS #possible_zeros;