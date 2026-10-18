# SQL practice set (12 questions) — try before looking at `practice/solutions/`

Tables: see README. Write each answer to `practice/my_answers/qNN.sql` (git-ignored), then check:
`~/ML_forecast/.venv/bin/python -m src.sq.check q01 practice/my_answers/q01.sql`
Column names do not matter; column order and values do. Round as the question says.

| # | Question | Main skill |
|---|---|---|
| q01 | 2025 total energy per zone in GWh (sum of MW over hours / 1000, 1 decimal), largest first. | GROUP BY, ORDER BY |
| q02 | For each month of 2025: the day and size (MW, rounded) of the highest **system** hourly load (sum of zones). Columns: month, date, MW; by month. | two-step aggregation, QUALIFY / ROW_NUMBER |
| q03 | Which 2025 dates have 25 hours (use zone COAST)? | HAVING |
| q04 | July 2025, per zone (alphabetical): average hourly MW on working days (not weekend, not holiday), on weekends, and weekend vs working-day % difference (2 decimals). | JOIN dim_date, conditional aggregation |
| q05 | COAST daily peak (MW, rounded) for 2025-08-01..2025-08-10 and its change vs the previous day (2025-08-01 compares with 2025-07-31). | LAG, filter after the window |
| q06 | For each zone, the 3 days of 2025 with the highest daily peak: zone, date, peak (rounded), rank 1-3. Order by zone, rank. | top-N per group |
| q07 | June 2025: daily system energy in GWh (2 decimals) and its 7-day trailing average (that day and the 6 before, 2 decimals). | window frames |
| q08 | 2025 per month: average DAM price at HB_HOUSTON minus average at HB_NORTH ($/MWh, 2 decimals). | pivot-style aggregation |
| q09 | 2025: number of negative-price DAM hours per hub (points starting with `HB_`) and total hours. Most negative hours first, then name. | LIKE with escape, conditional count |
| q10 | London 2013, households with >= 90% of the 17,520 half-hours: per tariff group (tou false/true) number of households, mean and median kWh per day (2 decimals). Readings are interval-end times: use ts_end_gmt > 2013-01-01 00:00 and <= 2014-01-01 00:00. | big-table aggregation |
| q11 | The 3 longest runs of consecutive 2025 days with COAST daily peak > 20,000 MW: start, end, number of days (longest first, then earliest). | gaps and islands |
| q12 | July-August 2025: regress NCENT daily peak (MW) on Dallas daily max temperature (local day, ERA5): slope (MW/°C, 1 decimal), R² (3 decimals), number of days. | regression in SQL, joining two aggregates |
