# Lakehouse: ELT по модели Medallion и бенчмарк форматов и сжатия

Практическая работа №1 по предмету «Основы теории информации».

- **Автор:** Лизинов Алтан Викторович (как в VK Education)
- **Вариант:** 4, запрос TPC-H Q16 «Parts/Supplier Relationship»
- **Масштаб данных:** `sf1`
- **Подробный отчёт с таблицами, обоснованиями и скриншотами:** [отчет.md](отчет.md)

## О чём работа

Локально развёрнут Lakehouse и выполнен полный цикл ELT на данных TPC-H (генерирует коннектор `tpch` в Trino, скачивать ничего не нужно):

1. **Bronze:** сырые таблицы `part`, `partsupp`, `supplier` без изменений.
2. **Silver:** очистка и нормализация, исключение поставщиков с жалобами, соединение `partsupp` и `part`.
3. **Gold:** витрина `brand, type, size, supplier_cnt`, отвечающая на запрос Q16.
4. **Проверка корректности:** результат Gold сравнён с исходным запросом на `tpch.sf1`.
5. **Бенчмарк:** сравнение форматов (Parquet, ORC) и кодеков (NONE, SNAPPY, ZSTD, GZIP) по размеру файлов, времени записи и скорости агрегации.
6. **Часть 2:** schema evolution, time travel и чтение Bronze вторым движком (StarRocks).

## Стек

| Компонент | Роль |
|---|---|
| silo (форк MinIO) | S3-совместимое объектное хранилище, бакет `examples` |
| PostgreSQL | метаданные каталога |
| Lakekeeper | Iceberg REST Catalog, warehouse `demo` |
| Trino | SQL-движок для ELT и бенчмарка |
| StarRocks | второй движок для части 2 |

Стек поднимается из готового примера Lakekeeper (`examples/minimal`), его копия лежит в `infra/`.

## Структура репозитория

```
.
├── infra/
│   ├── docker-compose.yaml            # стек: silo, db, lakekeeper, trino, starrocks
│   └── create-default-warehouse.json  # параметры warehouse demo
├── sql/
│   ├── 00_catalog.sql                 # создание каталога lakekeeper в Trino
│   ├── 01_bronze.sql                  # слой Bronze
│   ├── 02_silver.sql                  # слой Silver
│   ├── 02b_quality.sql                # проверки качества Silver
│   ├── 03_gold.sql                    # слой Gold
│   ├── 04_check.sql                   # сверка Gold с исходным запросом Q16
│   ├── 05_stats.sql                   # строки и вес таблиц
│   ├── 06_timetravel.sql              # снапшоты и восстановление
│   └── 07_starrocks.sql               # подключение StarRocks к каталогу
├── bench/
│   ├── bench.py                       # скрипт бенчмарка
│   └── results.csv                    # результаты замеров
├── docs/screens/                      # скриншоты для отчёта
└── отчет.md                           # отчёт
```

## Как воспроизвести

### Требования

- Docker Desktop (или другой Docker с Compose), рекомендуется 4 ядра и 8 ГБ памяти;
- Python 3.10+ (только для бенчмарка);
- свободные порты: 8181 (Lakekeeper), 9000 и 9001 (silo), 9999 (Trino), 9030 и 8030 (StarRocks).

### 1. Поднять стек

```bash
cd infra
docker compose up -d initialwarehouse   # silo, db, lakekeeper и одноразовая настройка
docker compose up -d trino
docker compose ps -a
```

Сервисы `silo`, `db`, `lakekeeper`, `trino` должны быть в статусе `Up (healthy)`. Одноразовые `create-bucket`, `migrate`, `bootstrap`, `initialwarehouse` завершаются со статусом `Exited (0)`, это нормально.

Интерфейсы:

- Lakekeeper: http://localhost:8181
- консоль silo: http://localhost:9001 (логин `silo-root-user`, пароль `silo-root-password`, это демо-доступы из примера)
- Trino: http://localhost:9999

### 2. Создать каталог и слои

Каталог в Trino создаётся вручную (в compose включено динамическое управление каталогами), поэтому после пересоздания контейнера Trino `00_catalog.sql` нужно выполнить заново. Из папки `infra`:

```bash
docker compose exec -T trino trino --pager= < ../sql/00_catalog.sql
docker compose exec -T trino trino --pager= < ../sql/01_bronze.sql
docker compose exec -T trino trino --pager= < ../sql/02_silver.sql
docker compose exec -T trino trino --pager= < ../sql/02b_quality.sql
docker compose exec -T trino trino --pager= < ../sql/03_gold.sql
docker compose exec -T trino trino --pager= < ../sql/04_check.sql
docker compose exec -T trino trino --pager= < ../sql/05_stats.sql
```

Результаты `04_check.sql`: число строк и сумма `supplier_cnt` в исходном запросе и в Gold должны совпасть.

### 3. Бенчмарк

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install trino
python3 bench/bench.py
```

Скрипт создаёт в схеме `bronze` копии таблицы `partsupp` с разными форматами и кодеками, замеряет размер, время записи и медиану времени агрегации (6 запусков, первый отбрасывается как прогрев) и пишет `bench/results.csv`. Скрипт подключается к Trino на `localhost:9999`.

### 4. Часть 2

`sql/06_timetravel.sql` содержит пример восстановления из снапшота. Значение `snapshot_id` зависит от конкретного запуска: перед выполнением нужно подставить свой идентификатор, который показывает запрос к `"part_supplier$snapshots"`.

StarRocks (внешний каталог Iceberg поверх Lakekeeper), из папки `infra`:

```bash
docker compose pull starrocks
docker compose up -d starrocks
docker compose exec -T starrocks mysql -P 9030 -h 127.0.0.1 -u root < ../sql/07_starrocks.sql
```

## Краткие результаты

Масштаб `sf1`, таблица `partsupp` (800 000 строк):

| Формат | Кодек | Размер, МБ | Запись, с | Запрос (медиана), с |
|---|---|---|---|---|
| Parquet | NONE | 106,89 | 1,03 | 0,058 |
| Parquet | SNAPPY | 39,02 | 0,92 | 0,050 |
| Parquet | ZSTD | 27,85 | 1,30 | 0,058 |
| Parquet | GZIP | 24,78 | 2,91 | 0,057 |
| ORC | ZSTD | 26,71 | 1,10 | 0,057 |

- GZIP сжимает сильнее всех (в 4,3 раза), но медленнее всех пишет.
- ZSTD даёт близкое сжатие (в 3,8 раза) при заметно более быстрой записи, поэтому выбран для слоёв.
- Разница во времени запроса на этом объёме лежит в пределах шума измерений.
- Витрина Gold: 18 314 строк, сумма `supplier_cnt` равна 118 250 и совпадает с исходным запросом.

Методика, ограничения и полный анализ описаны в [отчет.md](отчет.md).