SELECT point, count(*) FILTER (WHERE price < 0) AS negative_hours, count(*) AS hours
FROM fact_dam_price WHERE year(op_date) = 2025 AND point LIKE 'HB\_%' ESCAPE '\'
GROUP BY point ORDER BY negative_hours DESC, point;
