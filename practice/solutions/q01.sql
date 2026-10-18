SELECT zone, round(sum(mw) / 1000, 1) AS gwh
FROM fact_load_hourly WHERE year(op_date) = 2025
GROUP BY zone ORDER BY gwh DESC;
