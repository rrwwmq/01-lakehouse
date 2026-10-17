CREATE TABLE lakekeeper.silver.part_supplier WITH (format='PARQUET') AS
SELECT p.partkey, trim(p.brand) AS brand, trim(p.type) AS type, p.size, ps.suppkey
FROM lakekeeper.bronze.partsupp ps
JOIN lakekeeper.bronze.part p ON p.partkey = ps.partkey
WHERE ps.suppkey NOT IN (
  SELECT suppkey FROM lakekeeper.bronze.supplier
  WHERE comment LIKE '%Customer%Complaints%'
);