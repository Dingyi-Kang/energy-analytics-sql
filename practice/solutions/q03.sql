SELECT op_date FROM fact_load_hourly WHERE zone = 'COAST' AND year(op_date) = 2025
GROUP BY op_date HAVING count(*) = 25;
