SELECT 'bronze.part' AS tbl,
  (SELECT count(*) FROM lakekeeper.bronze.part) AS rows_,
  (SELECT round(sum(file_size_in_bytes)/1048576.0, 3) FROM lakekeeper.bronze."part$files") AS mb
UNION ALL SELECT 'bronze.partsupp',
  (SELECT count(*) FROM lakekeeper.bronze.partsupp),
  (SELECT round(sum(file_size_in_bytes)/1048576.0, 3) FROM lakekeeper.bronze."partsupp$files")
UNION ALL SELECT 'bronze.supplier',
  (SELECT count(*) FROM lakekeeper.bronze.supplier),
  (SELECT round(sum(file_size_in_bytes)/1048576.0, 3) FROM lakekeeper.bronze."supplier$files")
UNION ALL SELECT 'silver.part_supplier',
  (SELECT count(*) FROM lakekeeper.silver.part_supplier),
  (SELECT round(sum(file_size_in_bytes)/1048576.0, 3) FROM lakekeeper.silver."part_supplier$files")
UNION ALL SELECT 'gold.part_supplier_cnt',
  (SELECT count(*) FROM lakekeeper.gold.part_supplier_cnt),
  (SELECT round(sum(file_size_in_bytes)/1048576.0, 3) FROM lakekeeper.gold."part_supplier_cnt$files");