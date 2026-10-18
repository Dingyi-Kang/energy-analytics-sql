WITH d AS (SELECT op_date, max(mw) AS peak FROM fact_load_hourly WHERE zone = 'COAST' GROUP BY op_date)
SELECT op_date, round(peak) AS peak_mw, round(peak - lag(peak) OVER (ORDER BY op_date)) AS change_mw
FROM d QUALIFY op_date BETWEEN DATE '2025-08-01' AND DATE '2025-08-10'
ORDER BY op_date;
