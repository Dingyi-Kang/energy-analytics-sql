-- Q: Project D's selected model on its 2025 internal test: where is the error largest, by zone and
--    local hour? (Reads a predictions parquet registered as table `preds`.)
-- Skills: joining model output to facts, WAPE as ratio of sums, PIVOT-style conditional aggregation.
SELECT zone,
       round(100 * sum(abs(y - q50)) / sum(y), 2) AS wape_all,
       round(100 * sum(abs(y - q50)) FILTER (WHERE hour(timezone('America/Chicago', interval_start_utc)) BETWEEN 0 AND 5)
             / sum(y) FILTER (WHERE hour(timezone('America/Chicago', interval_start_utc)) BETWEEN 0 AND 5), 2) AS wape_night,
       round(100 * sum(abs(y - q50)) FILTER (WHERE hour(timezone('America/Chicago', interval_start_utc)) BETWEEN 14 AND 19)
             / sum(y) FILTER (WHERE hour(timezone('America/Chicago', interval_start_utc)) BETWEEN 14 AND 19), 2) AS wape_afternoon,
       round(100 * avg(CASE WHEN y BETWEEN q10 AND q90 THEN 1 ELSE 0 END), 1) AS cover80_pct
FROM preds GROUP BY zone ORDER BY wape_all DESC;
