CREATE SCHEMA IF NOT EXISTS lakekeeper.bronze;
CREATE SCHEMA IF NOT EXISTS lakekeeper.silver;
CREATE SCHEMA IF NOT EXISTS lakekeeper.gold;

CREATE TABLE lakekeeper.bronze.part     WITH (format='PARQUET') AS SELECT * FROM tpch.sf1.part;
CREATE TABLE lakekeeper.bronze.partsupp WITH (format='PARQUET') AS SELECT * FROM tpch.sf1.partsupp;
CREATE TABLE lakekeeper.bronze.supplier WITH (format='PARQUET') AS SELECT * FROM tpch.sf1.supplier;