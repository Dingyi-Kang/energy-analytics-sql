-- Q: London 2013: how concentrated is household consumption? Share of energy by consumption decile,
--    for households with >= 90% of half-hours present. (168M-row table: filter early, aggregate once.)
-- Skills: large-table aggregation, HAVING on coverage, NTILE, share of total with a window.
WITH hh AS (
  SELECT household, any_value(tou) AS tou, sum(kwh) AS kwh, count(*) AS n
  FROM fact_meter_hh
  WHERE ts_end_gmt > TIMESTAMP '2013-01-01 00:00:00' AND ts_end_gmt <= TIMESTAMP '2014-01-01 00:00:00'
  GROUP BY household
  HAVING count(*) >= 0.9 * 17520),
d AS (SELECT *, ntile(10) OVER (ORDER BY kwh / n) AS decile FROM hh)
SELECT decile, count(*) AS households, round(avg(kwh / n * 48), 2) AS mean_kwh_per_day,
       round(100 * sum(kwh) / sum(sum(kwh)) OVER (), 2) AS share_of_energy_pct
FROM d GROUP BY decile ORDER BY decile;
