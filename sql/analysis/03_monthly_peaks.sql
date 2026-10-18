-- Q: For June-September each year, which day and hour had the highest ERCOT hourly load (4CP-like)?
-- Skills: aggregate to system level, ROW_NUMBER + QUALIFY (exists in DuckDB and Snowflake).
WITH sys AS (
  SELECT ts_utc, any_value(ts_local) AS ts_local, any_value(op_date) AS op_date, sum(mw) AS mw
  FROM fact_load_hourly GROUP BY ts_utc)
SELECT year(op_date) AS year, month(op_date) AS month, op_date, hour(ts_local) AS local_hour_start, round(mw) AS mw
FROM sys WHERE month(op_date) BETWEEN 6 AND 9
QUALIFY row_number() OVER (PARTITION BY year(op_date), month(op_date) ORDER BY mw DESC) = 1
ORDER BY year, month;
