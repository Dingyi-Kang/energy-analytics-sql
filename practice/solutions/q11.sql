-- gaps and islands: consecutive days with COAST daily peak > 20,000 MW in 2025
WITH d AS (SELECT op_date, max(mw) AS peak FROM fact_load_hourly WHERE zone = 'COAST' AND year(op_date) = 2025 GROUP BY op_date),
hot AS (SELECT op_date, op_date - CAST(row_number() OVER (ORDER BY op_date) AS INTEGER) AS grp FROM d WHERE peak > 20000)
SELECT min(op_date) AS start_date, max(op_date) AS end_date, count(*) AS days
FROM hot GROUP BY grp ORDER BY days DESC, start_date LIMIT 3;
