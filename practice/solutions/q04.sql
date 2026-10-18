SELECT l.zone,
       round(avg(mw) FILTER (WHERE NOT d.is_weekend AND NOT d.is_holiday), 1) AS workday_avg_mw,
       round(avg(mw) FILTER (WHERE d.is_weekend), 1) AS weekend_avg_mw,
       round(100 * (avg(mw) FILTER (WHERE d.is_weekend) / avg(mw) FILTER (WHERE NOT d.is_weekend AND NOT d.is_holiday) - 1), 2) AS weekend_vs_workday_pct
FROM fact_load_hourly l JOIN dim_date d USING (op_date)
WHERE d.year = 2025 AND d.month = 7
GROUP BY l.zone ORDER BY l.zone;
