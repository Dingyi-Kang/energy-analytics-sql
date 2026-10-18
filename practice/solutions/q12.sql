WITH lp AS (SELECT op_date, max(mw) AS peak FROM fact_load_hourly WHERE zone = 'NCENT' GROUP BY op_date),
tx AS (SELECT CAST(timezone('America/Chicago', ts_utc) AS DATE) AS op_date, max(temp_c) AS tmax
       FROM fact_weather_hourly WHERE city = 'dallas' GROUP BY 1)
SELECT round(regr_slope(peak, tmax), 1) AS mw_per_degc, round(regr_r2(peak, tmax), 3) AS r2, count(*) AS days
FROM lp JOIN tx USING (op_date)
WHERE op_date BETWEEN DATE '2025-07-01' AND DATE '2025-08-31';
