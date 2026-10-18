SELECT month(op_date) AS month,
       round(avg(price) FILTER (WHERE point = 'HB_HOUSTON') - avg(price) FILTER (WHERE point = 'HB_NORTH'), 2) AS houston_minus_north
FROM fact_dam_price WHERE year(op_date) = 2025
GROUP BY ALL ORDER BY month;
