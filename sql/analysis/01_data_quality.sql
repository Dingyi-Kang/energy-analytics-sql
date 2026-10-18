-- Q: Is the hourly zone load complete? Days with != 24 hours should be exactly the DST days.
-- Skills: GROUP BY / HAVING, COUNT DISTINCT, conditional aggregation.
WITH per_day AS (
  SELECT op_date, zone, count(*) AS n_hours, count(DISTINCT ts_utc) AS n_distinct,
         sum(CASE WHEN mw IS NULL THEN 1 ELSE 0 END) AS n_null
  FROM fact_load_hourly GROUP BY op_date, zone)
SELECT n_hours, count(DISTINCT op_date) AS days, sum(n_hours - n_distinct) AS duplicate_rows, sum(n_null) AS null_rows
FROM per_day GROUP BY n_hours ORDER BY n_hours;
