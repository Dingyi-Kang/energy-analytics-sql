# Energy analytics in SQL (Project F)

Runs on **DuckDB**; notes on porting to Snowflake are at the end.
Public data reused from Projects 1, A and C (ERCOT load and DAM prices, Open-Meteo/ERA5, ERCOT load
profiles, Low Carbon London smart meters CC BY 4.0). Not affiliated with ERCOT, UK Power Networks or Vistra.

## Warehouse (`python -m src.sq.build` -> data/warehouse.duckdb)
| Table | Rows | Grain |
|---|---|---|
| fact_load_hourly | 683,512 | hour (UTC) x ERCOT weather zone, MW; local time, operating day, hour ending, DST repeat flag |
| fact_dam_price | 1,265,386 | operating day x hour ending x hub / load zone, $/MWh |
| fact_weather_hourly | 948,288 | hour x city, ERA5 temperature and dew point |
| fact_profile_hourly | 20,998,408 | ERCOT profile class x zone x hour, kWh per meter |
| fact_esiid_counts | 98,715 | snapshot x zone x meter type x TDSP x profile, meter counts |
| fact_meter_hh (view) | 167,932,474 | London household x half-hour (interval end, GMT), kWh |
| dim_date, dim_zone | 3,652 / 11 | calendar with holidays; zone -> weather cities |

## Analyses (`python -m src.sq.run`), each re-computed in pandas in `tests/test_sql.py`
| File | Business question | Result (short) |
|---|---|---|
| 01 | Is hourly load complete? | 3,541 days x 24 h, 10 x 23 h, 9 x 25 h (= DST days); no duplicates, no nulls |
| 02 | Monthly energy, zone share, YoY growth | e.g. NCENT and COAST each ~28-30% of ERCOT energy |
| 03 | Monthly summer peak day and hour (4CP-like) | peaks at 16:00-18:00 local, every year |
| 04 | MW per +1 °C on hot summer weekday afternoons (2025, regression in SQL) | NCENT +788 MW/°C (R² 0.88), COAST +608; FWEST ~0 (R² 0.08: oil-field load, not weather) |
| 05 | Time-average vs load-weighted DAM price | load-weighted is 1-22% higher (Jan 2024 winter storm: +22%) |
| 06 | Most unusual daily peaks vs previous 4 weeks | 2022-12-22 winter storm Elliott (z = +9), 2024-07-08 Hurricane Beryl outages (z = -4.7), 2024-10-16 cold front |
| 07 | London 2013: consumption concentration | top 10% of households use 26% of energy, bottom 10% use 2.6% |
| 08 | Project D test errors by zone and time of day | afternoon WAPE > night WAPE in every zone; NORTH worst |

## Practice set: [practice/questions.md](practice/questions.md)
12 interview-style questions with an automatic checker; reference solutions in `practice/solutions/`
(do not open before trying). `python -m src.sq.check q05 practice/my_answers/q05.sql`

## DuckDB vs Snowflake (things that change when moving these queries)
- Reading files: DuckDB reads `'file.parquet'` directly; Snowflake loads from a stage (`COPY INTO`, external tables).
- Time zones: DuckDB `timezone('America/Chicago', ts)`; Snowflake `CONVERT_TIMEZONE('UTC', 'America/Chicago', ts)`.
- Aggregate `FILTER (WHERE ...)` (used here): write `SUM(CASE WHEN ... THEN x END)` or `COUNT_IF` in Snowflake.
- Date arithmetic: `date - integer` (q11) -> `DATEADD(day, -n, date)` in Snowflake.
- Same idea in both: `QUALIFY`, window functions, `REGR_SLOPE` / `REGR_R2`, `UNPIVOT` (different syntax), `MEDIAN`, `NTILE`.
