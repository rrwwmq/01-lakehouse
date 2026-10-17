import csv
import statistics
import time

import trino

CAT = "lakekeeper"
conn = trino.dbapi.connect(host="localhost", port=9999, user="bench", catalog=CAT, schema="bronze")
cur = conn.cursor()


def run(sql):
    t = time.perf_counter()
    cur.execute(sql)
    res = cur.fetchall()
    return time.perf_counter() - t, res


variants = [
    ("PARQUET", "ZSTD"),
    ("PARQUET", "GZIP"),
    ("PARQUET", "SNAPPY"),
    ("PARQUET", "NONE"),
    ("ORC", "ZSTD"),
]

rows = []
for fmt, codec in variants:
    tbl = f"partsupp_{fmt.lower()}_{codec.lower()}"
    run(f"SET SESSION {CAT}.compression_codec = '{codec}'")
    run(f"DROP TABLE IF EXISTS bronze.{tbl}")
    write_s, _ = run(f"CREATE TABLE bronze.{tbl} WITH (format='{fmt}') AS SELECT * FROM tpch.sf1.partsupp")
    _, r = run(f'SELECT sum(file_size_in_bytes) FROM bronze."{tbl}$files"')
    size_mb = r[0][0] / 1048576
    times = [run(f"SELECT suppkey, count(*) FROM bronze.{tbl} GROUP BY suppkey")[0] for _ in range(6)]
    median_s = statistics.median(times[1:])  # первый прогон считаем прогревом
    rows.append([fmt, codec, round(size_mb, 2), round(write_s, 2), round(median_s, 3)])
    print(rows[-1])

with open("bench/results.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["format", "codec", "size_mb", "write_s", "query_median_s"])
    w.writerows(rows)