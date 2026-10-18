WITH hh AS (
  SELECT household, any_value(tou) AS tou, sum(kwh) AS kwh, count(*) AS n
  FROM fact_meter_hh
  WHERE ts_end_gmt > TIMESTAMP '2013-01-01 00:00:00' AND ts_end_gmt <= TIMESTAMP '2014-01-01 00:00:00'
  GROUP BY household HAVING count(*) >= 0.9 * 17520)
SELECT tou, count(*) AS households, round(avg(kwh / n * 48), 2) AS mean_kwh_per_day,
       round(median(kwh / n * 48), 2) AS median_kwh_per_day
FROM hh GROUP BY tou ORDER BY tou;
