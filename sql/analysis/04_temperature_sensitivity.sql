-- Q: How many MW does each zone add per +1 deg C on hot summer weekday afternoons?
-- Skills: JOIN facts on time, zone temperature as mean of its cities, linear regression in SQL
--         (REGR_SLOPE / REGR_INTERCEPT / REGR_R2 exist in DuckDB and Snowflake).
WITH zt AS (
  SELECT z.zone, w.ts_utc, avg(w.temp_c) AS temp_c
  FROM fact_weather_hourly w JOIN dim_zone z USING (city) GROUP BY ALL)
SELECT l.zone,
       round(regr_slope(l.mw, zt.temp_c), 1) AS mw_per_degc,
       round(regr_intercept(l.mw, zt.temp_c)) AS intercept_mw,
       round(regr_r2(l.mw, zt.temp_c), 3) AS r2,
       count(*) AS n_hours
FROM fact_load_hourly l
JOIN zt ON zt.zone = l.zone AND zt.ts_utc = l.ts_utc
JOIN dim_date d ON d.op_date = l.op_date
WHERE d.year = 2025 AND d.month BETWEEN 6 AND 9 AND NOT d.is_weekend AND NOT d.is_holiday
  AND hour(l.ts_local) BETWEEN 14 AND 18 AND zt.temp_c >= 25
GROUP BY l.zone ORDER BY mw_per_degc DESC;
