   Silver part_supplier: 799680 строк
   dublicates=0, nulls=0

             tbl           | rows_  |  mb  
------------------------+--------+------
 bronze.supplier        |  10000 |  0.5 
 gold.part_supplier_cnt |  18314 |  0.0 
 silver.part_supplier   | 799680 |  3.4 
 bronze.partsupp        | 800000 | 27.9 
 bronze.part            | 200000 |  4.1 

 trino> SELECT snapshot_id, committed_at, operation FROM lakekeeper.silver."part_supplier$snapshots" ORDER BY committed_at;
     snapshot_id     |        committed_at         | operation 
---------------------+-----------------------------+-----------
 1400880752776702163 | 2026-10-17 12:27:40.023 UTC | append    
(1 row)

до
trino> SELECT count(*) FROM lakekeeper.silver.part_supplier;
 _col0  
--------
 799680 
(1 row)

после
trino> SELECT count(*) FROM lakekeeper.silver.part_supplier;
 _col0  
--------
 783196 
(1 row)