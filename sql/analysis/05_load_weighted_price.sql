-- Q: Per month, the time-average vs load-weighted average day-ahead price at the hub average
--    (a retailer buys more energy in expensive hours: the gap is the "shape premium").
-- Skills: join keys with DST (repeated hour), weighted averages, ratio of sums.
WITH sys AS (
  SELECT op_date, he, dst_rep, sum(mw) AS mw FROM fact_load_hourly GROUP BY ALL),
p AS (SELECT op_date, he, dst_rep, price FROM fact_dam_price WHERE point = 'HB_BUSAVG')
SELECT date_trunc('month', s.op_date) AS month,
       round(avg(p.price), 2) AS time_avg_price,
       round(sum(p.price * s.mw) / sum(s.mw), 2) AS load_weighted_price,
       round(sum(p.price * s.mw) / sum(s.mw) / avg(p.price), 3) AS shape_ratio,
       count(*) AS hours
FROM sys s JOIN p USING (op_date, he, dst_rep)
WHERE s.op_date >= DATE '2024-01-01' AND s.op_date < DATE '2026-10-01'
GROUP BY ALL ORDER BY month;
