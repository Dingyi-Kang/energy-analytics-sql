"""Every analysis query is re-computed independently in pandas/numpy (from the
source parquet files, not from the warehouse) and compared."""
from pathlib import Path
import numpy as np
import pandas as pd
import pytest
from src.sq.run import run, PREDS
from src.sq.build import PATHS

TZ = "America/Chicago"
ZONES = ["COAST", "EAST", "FWEST", "NORTH", "NCENT", "SOUTH", "SCENT", "WEST"]


@pytest.fixture(scope="module")
def load():
    L = pd.read_parquet(PATHS["P1"] / "load_hourly.parquet")
    L["op_date"] = pd.to_datetime(L["op_date"])
    L["sys"] = L[ZONES].sum(axis=1)
    L["local"] = pd.DatetimeIndex(L["interval_start_utc"]).tz_convert(TZ)
    return L


def test_01_quality(load):
    q = run("01")
    n = load.groupby("op_date").size().value_counts().sort_index()
    assert dict(zip(q["n_hours"], q["days"])) == n.to_dict()
    assert q["duplicate_rows"].sum() == 0 and q["null_rows"].sum() == 0


def test_02_monthly_yoy(load):
    q = run("02")
    L = load[load["op_date"] < "2026-10-01"]
    m = L.groupby(L["op_date"].dt.to_period("M"))[ZONES].sum() / 1000
    yoy = 100 * (m / m.shift(12) - 1)
    r = q[(q["zone"] == "NCENT") & (q["month"] == pd.Timestamp("2025-07-01"))].iloc[0]
    assert abs(r["gwh"] - m.loc["2025-07", "NCENT"]) < 0.1
    assert abs(r["yoy_pct"] - yoy.loc["2025-07", "NCENT"]) < 0.01
    assert abs(r["share_pct"] - 100 * m.loc["2025-07", "NCENT"] / m.loc["2025-07"].sum()) < 0.01


def test_03_peaks(load):
    q = run("03")
    s = load[load["op_date"].dt.month.between(6, 9)]
    idx = s.groupby([s["op_date"].dt.year, s["op_date"].dt.month])["sys"].idxmax()
    pk = s.loc[idx.values]
    assert list(pd.to_datetime(q["op_date"])) == list(pk["op_date"])
    assert np.allclose(q["mw"].values, pk["sys"].round().values)


def test_04_regression(load):
    q = run("04").set_index("zone")
    W = pd.read_parquet(PATHS["P1"] / "weather_obs_era5.parquet").reset_index()
    city = {"COAST": ["houston"], "NCENT": ["dallas", "fortworth"]}
    hol = pd.read_parquet(PATHS["P1"] / "features_A0.parquet", columns=["T", "is_holiday"]).drop_duplicates("T")
    hol = set(pd.to_datetime(hol.loc[hol["is_holiday"] == 1, "T"]))
    for z, cs in city.items():
        t = W[W["city"].isin(cs)].groupby("time")["temperature_2m"].mean()
        d = load[["interval_start_utc", "op_date", "local", z]].copy()
        d["temp"] = t.reindex(pd.DatetimeIndex(d["interval_start_utc"])).values
        d = d[(d["op_date"].dt.year == 2025) & d["op_date"].dt.month.between(6, 9) & (d["op_date"].dt.dayofweek < 5)
              & ~d["op_date"].isin(hol) & d["local"].dt.hour.between(14, 18) & (d["temp"] >= 25)]
        slope, icpt = np.polyfit(d["temp"], d[z], 1)
        assert len(d) == q.loc[z, "n_hours"]
        assert abs(slope - q.loc[z, "mw_per_degc"]) < 0.1


def test_05_weighted_price(load):
    q = run("05").set_index("month")
    P = pd.read_parquet(PATHS["P1"] / "dam_prices.parquet")[["T", "slot", "rep", "HB_BUSAVG"]]
    P["T"] = pd.to_datetime(P["T"])
    m = load.merge(P, left_on=["op_date", "he", load["dst_tag"].astype(int)], right_on=["T", "slot", "rep"])
    m = m[(m["op_date"] >= "2025-07-01") & (m["op_date"] < "2025-08-01")]
    lw = (m["HB_BUSAVG"] * m["sys"]).sum() / m["sys"].sum()
    assert abs(q.loc[pd.Timestamp("2025-07-01"), "load_weighted_price"] - lw) < 0.01
    assert abs(q.loc[pd.Timestamp("2025-07-01"), "time_avg_price"] - m["HB_BUSAVG"].mean()) < 0.01


def test_06_anomalies(load):
    q = run("06")
    d = load.groupby("op_date")["sys"].max()
    mu = d.shift(1).rolling(28).mean(); sd = d.shift(1).rolling(28).std()
    z = ((d - mu) / sd)[d.index < "2026-10-01"].dropna()
    top = z.reindex(z.abs().sort_values(ascending=False).index[:10])
    assert list(pd.to_datetime(q["op_date"])) == list(top.index)
    assert np.allclose(q["z"].values, top.round(2).values)


def test_07_deciles_against_project_c_panel():
    q = run("07")
    C = Path.home() / "ML_smart_meter_london/data/processed"
    cov = pd.read_parquet(C / "coverage.parquet")
    n_c = int((cov["cov_2013"] >= 0.9).sum())          # Project C's independent panel (numpy matrix)
    assert abs(q["households"].sum() - n_c) / n_c < 0.01
    assert abs(q["share_of_energy_pct"].sum() - 100) < 0.05
    assert q["mean_kwh_per_day"].is_monotonic_increasing


def test_08_forecast_error():
    q = run("08").set_index("zone")
    P = pd.read_parquet(PREDS)
    g = P.groupby("zone")
    w = 100 * g.apply(lambda x: (x["y"] - x["q50"]).abs().sum() / x["y"].sum())
    assert np.allclose(q.loc[w.index, "wape_all"], w.round(2), atol=0.006)


def test_practice_solutions_pass_their_own_check():
    from src.sq.check import compare
    for f in sorted(Path("practice/solutions").glob("q*.sql")):
        ok, msg = compare(f.stem, f.read_text())
        assert ok, (f.stem, msg)
