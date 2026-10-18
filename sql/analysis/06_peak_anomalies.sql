-- Q: Which days had the most unusual daily peak relative to the previous 4 weeks (z-score)?
-- Skills: two-level aggregation, window frames (ROWS BETWEEN ... PRECEDING), STDDEV, NULLIF.
WITH daily AS (
  SELECT op_date, max(mw) AS peak FROM (
    SELECT op_date, ts_utc, sum(mw) AS mw FROM fact_load_hourly GROUP BY ALL) GROUP BY op_date),
w AS (
  SELECT op_date, peak,
         avg(peak) OVER (ORDER BY op_date ROWS BETWEEN 28 PRECEDING AND 1 PRECEDING) AS mean28,
         stddev_samp(peak) OVER (ORDER BY op_date ROWS BETWEEN 28 PRECEDING AND 1 PRECEDING) AS sd28,
         count(*) OVER (ORDER BY op_date ROWS BETWEEN 28 PRECEDING AND 1 PRECEDING) AS n_prev
  FROM daily)
SELECT op_date, round(peak) AS peak, round(mean28) AS mean28, round((peak - mean28) / nullif(sd28, 0), 2) AS z
FROM w WHERE n_prev = 28 AND op_date < DATE '2026-10-01'
ORDER BY abs((peak - mean28) / nullif(sd28, 0)) DESC LIMIT 10;
