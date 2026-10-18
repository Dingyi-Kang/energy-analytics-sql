-- Project F warehouse (DuckDB). {P1}, {PA}, {PC} = processed-data folders of
-- Projects 1, A and C (read-only). Times are stored in UTC; local (America/Chicago) columns are derived.
SET TimeZone = 'UTC';

CREATE OR REPLACE TABLE dim_zone AS
SELECT * FROM (VALUES
  ('COAST', 'houston'), ('EAST', 'tyler'), ('FWEST', 'midland'), ('NORTH', 'wichitafalls'),
  ('NCENT', 'dallas'), ('NCENT', 'fortworth'), ('SOUTH', 'corpus'), ('SOUTH', 'mcallen'),
  ('SCENT', 'sanantonio'), ('SCENT', 'austin'), ('WEST', 'abilene')) AS t(zone, city);

-- one row per (hour, zone); UNPIVOT turns the 8 zone columns into rows
CREATE OR REPLACE TABLE fact_load_hourly AS
SELECT interval_start_utc::TIMESTAMPTZ AS ts_utc,
       timezone('America/Chicago', interval_start_utc::TIMESTAMPTZ) AS ts_local,
       op_date::DATE AS op_date, he, dst_tag::INT AS dst_rep, zone, mw
FROM (UNPIVOT (SELECT interval_start_utc, op_date, he, dst_tag, COAST, EAST, FWEST, NORTH, NCENT, SOUTH, SCENT, WEST
               FROM '{P1}/load_hourly.parquet')
      ON COAST, EAST, FWEST, NORTH, NCENT, SOUTH, SCENT, WEST INTO NAME zone VALUE mw);

CREATE OR REPLACE TABLE fact_weather_hourly AS        -- ERA5 reanalysis (observed proxy), deg C
SELECT city, "time"::TIMESTAMPTZ AS ts_utc, temperature_2m AS temp_c, dew_point_2m AS dew_c
FROM '{P1}/weather_obs_era5.parquet';

CREATE OR REPLACE TABLE fact_dam_price AS             -- ERCOT day-ahead settlement point prices, $/MWh
SELECT T::DATE AS op_date, slot AS he, rep AS dst_rep, point, price
FROM (UNPIVOT (SELECT * FROM '{P1}/dam_prices.parquet') ON COLUMNS('^(HB|LZ)_') INTO NAME point VALUE price);

CREATE OR REPLACE TABLE dim_date AS
SELECT d::DATE AS op_date, dayofweek(d) AS dow, month(d) AS month, year(d) AS year,
       dayofweek(d) IN (0, 6) AS is_weekend,
       coalesce(h.is_holiday, 0) = 1 AS is_holiday
FROM generate_series(DATE '2017-01-01', DATE '2026-12-31', INTERVAL 1 DAY) g(d)
LEFT JOIN (SELECT DISTINCT T::DATE AS op_date, is_holiday FROM '{P1}/features_A0.parquet') h ON h.op_date = g.d::DATE;

CREATE OR REPLACE TABLE fact_profile_hourly AS        -- Project A: ERCOT load-profile class x zone, kWh per meter
SELECT split_part(series, '_', 1) AS profile, split_part(series, '_', 2) AS zone,
       op_date::DATE AS op_date, hour_utc::TIMESTAMPTZ AS ts_utc, kwh, n
FROM '{PA}/profiles_hourly.parquet';

CREATE OR REPLACE TABLE fact_esiid_counts AS SELECT * FROM '{PA}/counts.parquet';

-- London smart meters (Project C), 168M rows: a VIEW, so DuckDB scans the parquet file on demand
CREATE OR REPLACE VIEW fact_meter_hh AS
SELECT LCLid AS household, tou, ts::TIMESTAMP AS ts_end_gmt, kwh FROM '{PC}/hh.parquet';
