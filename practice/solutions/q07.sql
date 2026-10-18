WITH d AS (SELECT op_date, sum(mw) / 1000 AS gwh FROM fact_load_hourly GROUP BY op_date)
SELECT op_date, round(gwh, 2) AS gwh,
       round(avg(gwh) OVER (ORDER BY op_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS gwh_7d_avg
FROM d QUALIFY op_date BETWEEN DATE '2025-06-01' AND DATE '2025-06-30'
ORDER BY op_date;
