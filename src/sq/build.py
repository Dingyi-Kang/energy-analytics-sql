"""Build data/warehouse.duckdb from Projects 1, A, C (read-only inputs).
python -m src.sq.build"""
from pathlib import Path
import duckdb

HOME = Path.home()
PATHS = {"P1": HOME / "ML_forecast/data/processed", "PA": HOME / "ML_retail_usage/data/processed",
         "PC": HOME / "ML_smart_meter_london/data/processed"}
DB = Path("data/warehouse.duckdb")


def connect(read_only=True):
    con = duckdb.connect(str(DB), read_only=read_only)
    con.execute("SET TimeZone = 'UTC'")
    return con


def main():
    sql = Path("sql/00_build.sql").read_text()
    for k, v in PATHS.items():
        sql = sql.replace("{" + k + "}", str(v))
    DB.parent.mkdir(exist_ok=True)
    con = duckdb.connect(str(DB))
    con.execute(sql)
    for (t,) in con.execute("SELECT table_name FROM information_schema.tables ORDER BY 1").fetchall():
        print(f"{t:22s}", con.execute(f"SELECT count(*) FROM {t}").fetchone()[0])


if __name__ == "__main__":
    main()
