SELECT count(*) AS total_rows FROM lakekeeper.silver.part_supplier;
SELECT count(*) - count(DISTINCT (partkey, suppkey)) AS duplicates FROM lakekeeper.silver.part_supplier;
SELECT count_if(brand IS NULL OR type IS NULL OR size IS NULL) AS nulls FROM lakekeeper.silver.part_supplier;