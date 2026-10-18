WITH sys AS (SELECT op_date, ts_utc, sum(mw) AS mw FROM fact_load_hourly WHERE year(op_date) = 2025 GROUP BY ALL)
SELECT month(op_date) AS month, op_date, round(mw) AS peak_mw
FROM sys QUALIFY row_number() OVER (PARTITION BY month(op_date) ORDER BY mw DESC) = 1
ORDER BY month;
