SELECT count(*) AS rows_, sum(supplier_cnt) AS total FROM (
  SELECT p.brand, p.type, p.size, count(DISTINCT ps.suppkey) AS supplier_cnt
  FROM tpch.sf1.partsupp AS ps
  JOIN tpch.sf1.part AS p ON p.partkey = ps.partkey
  WHERE p.brand <> 'Brand#45'
    AND p.type NOT LIKE 'MEDIUM POLISHED%'
    AND p.size IN (49, 14, 23, 45, 19, 3, 36, 9)
    AND ps.suppkey NOT IN (
      SELECT suppkey FROM tpch.sf1.supplier
      WHERE comment LIKE '%Customer%Complaints%'
    )
  GROUP BY p.brand, p.type, p.size
);

SELECT count(*) AS rows_, sum(supplier_cnt) AS total FROM lakekeeper.gold.part_supplier_cnt;