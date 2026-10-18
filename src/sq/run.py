"""Run one or all analysis queries: python -m src.sq.run [01 02 ...]"""
import sys, time
from pathlib import Path
import pandas as pd
from .build import connect

PREDS = Path.home() / "ML_transformer_load/reports/preds/D3_chronos2_lora__test.parquet"


def run(name, con=None):
    con = con or connect()
    if name.startswith("08"):
        con.register("preds", pd.read_parquet(PREDS))
    f = next(Path("sql/analysis").glob(f"{name}*.sql"))
    return con.execute(f.read_text()).df()


if __name__ == "__main__":
    names = sys.argv[1:] or sorted(p.name[:2] for p in Path("sql/analysis").glob("*.sql"))
    pd.set_option("display.width", 200)
    for n in names:
        t = time.time(); df = run(n)
        print(f"== {n}  ({time.time() - t:.1f}s, {len(df)} rows)")
        print(df.head(14).to_string(index=False))
