"""Self-check for the practice set:
    python -m src.sq.check q03 my_answer.sql
Compares your result with the reference by column position (names ignored), row order ignored unless
the question asks for an order, numbers within 0.1% (or 0.05 absolute). Prints the first difference."""
import sys
from pathlib import Path
import numpy as np
import pandas as pd
from .build import connect

ORDERED = {"q01", "q02", "q05", "q06", "q07", "q08", "q09", "q11"}


def _norm(df):
    df = df.copy()
    for c in df.columns:
        if pd.api.types.is_datetime64_any_dtype(df[c]) or (df[c].dtype == object and len(df) and hasattr(df[c].iloc[0], "isoformat")):
            df[c] = pd.to_datetime(df[c]).dt.strftime("%Y-%m-%d")
    df.columns = range(df.shape[1])
    return df


def compare(q, answer_sql):
    con = connect()
    ref = _norm(con.execute(Path(f"practice/solutions/{q}.sql").read_text()).df())
    got = _norm(con.execute(answer_sql).df())
    if got.shape != ref.shape:
        return False, f"shape {got.shape}, expected {ref.shape}"
    if q not in ORDERED:
        ref = ref.sort_values(list(ref.columns)).reset_index(drop=True)
        got = got.sort_values(list(got.columns)).reset_index(drop=True)
    for c in ref.columns:
        a, b = got[c], ref[c]
        if pd.api.types.is_numeric_dtype(b) and pd.api.types.is_numeric_dtype(a):
            ok = np.isclose(a.astype(float), b.astype(float), rtol=1e-3, atol=0.05, equal_nan=True)
        else:
            ok = (a.astype(str) == b.astype(str)).values
        if not ok.all():
            i = int(np.flatnonzero(~ok)[0])
            return False, f"column {c + 1}, row {i + 1}: got {a.iloc[i]!r}, expected {b.iloc[i]!r}"
    return True, f"correct ({len(ref)} rows)"


if __name__ == "__main__":
    ok, msg = compare(sys.argv[1], Path(sys.argv[2]).read_text())
    print(("PASS: " if ok else "NOT YET: ") + msg)
