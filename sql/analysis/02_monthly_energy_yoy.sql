-- Q: Monthly energy (GWh) per zone, its share of ERCOT, and year-over-year growth.
-- Skills: DATE_TRUNC, window SUM for shares, LAG over a partition for YoY.
WITH m AS (
  SELECT zone, date_trunc('month', op_date) AS month, sum(mw) / 1000 AS gwh
  FROM fact_load_hourly WHERE op_date < DATE '2026-10-01' GROUP BY ALL)
SELECT zone, month, round(gwh, 1) AS gwh,
       round(100 * gwh / sum(gwh) OVER (PARTITION BY month), 2) AS share_pct,
       round(100 * (gwh / lag(gwh, 12) OVER (PARTITION BY zone ORDER BY month) - 1), 2) AS yoy_pct
FROM m ORDER BY zone, month;
