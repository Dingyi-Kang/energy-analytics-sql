WITH d AS (SELECT zone, op_date, max(mw) AS peak FROM fact_load_hourly WHERE year(op_date) = 2025 GROUP BY ALL)
SELECT zone, op_date, round(peak) AS peak_mw,
       row_number() OVER (PARTITION BY zone ORDER BY peak DESC) AS rnk
FROM d QUALIFY rnk <= 3 ORDER BY zone, rnk;
