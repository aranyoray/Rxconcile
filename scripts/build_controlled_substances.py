#!/usr/bin/env python3
"""Regenerate the controlled-substances dataset bundled with Rxconcile.

Source: the openFDA NDC Directory (https://open.fda.gov/apis/drug/ndc/), whose
records carry a `dea_schedule` field (e.g. "CII", "CIV"). We page through every
record that has a DEA schedule and build two maps:

  - ingredients: lowercased generic/brand name  -> schedule (II..V)
  - ndc:         product_ndc / package NDC       -> schedule (II..V)

Run:
    python3 scripts/build_controlled_substances.py            # write dataset
    python3 scripts/build_controlled_substances.py --check    # validate only

If openFDA is unreachable (e.g. restricted network), the existing seed file is
left untouched and the script exits non-zero so CI can flag it.
"""
from __future__ import annotations
import argparse, json, sys, time, urllib.request, urllib.error
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "Sources/Rxconcile/Resources/Data/controlled_substances.json"
ENDPOINT = "https://api.fda.gov/drug/ndc.json"
SCHEDULE_MAP = {"CI": "I", "CII": "II", "CIII": "III", "CIV": "IV", "CV": "V"}


def fetch_all(limit: int = 1000, max_records: int = 50000) -> list[dict]:
    results, skip = [], 0
    while skip < max_records:
        url = f"{ENDPOINT}?search=_exists_:dea_schedule&limit={limit}&skip={skip}"
        req = urllib.request.Request(url, headers={"User-Agent": "Rxconcile-dataset-builder"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            payload = json.load(resp)
        batch = payload.get("results", [])
        if not batch:
            break
        results.extend(batch)
        skip += limit
        time.sleep(0.3)  # be polite to the public API
    return results


def build(records: list[dict]) -> dict:
    ingredients: dict[str, str] = {}
    ndc: dict[str, str] = {}
    for r in records:
        sched = SCHEDULE_MAP.get((r.get("dea_schedule") or "").upper())
        if not sched:
            continue
        if code := r.get("product_ndc"):
            ndc[code] = sched
        for name in filter(None, [r.get("generic_name"), r.get("brand_name")]):
            ingredients[name.strip().lower()] = sched
        for ing in r.get("active_ingredients", []) or []:
            if n := ing.get("name"):
                ingredients[n.strip().lower()] = sched
    return {"ingredients": ingredients, "ndc": ndc}


def load_seed() -> dict:
    return json.loads(OUT.read_text())


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="validate the existing file only")
    args = ap.parse_args()

    if args.check:
        data = load_seed()
        assert isinstance(data.get("ingredients"), dict) and data["ingredients"], "ingredients map missing"
        assert isinstance(data.get("ndc"), dict), "ndc map missing"
        bad = {v for v in data["ingredients"].values()} - set(SCHEDULE_MAP.values())
        assert not bad, f"unexpected schedule values: {bad}"
        print(f"OK: {len(data['ingredients'])} ingredients, {len(data['ndc'])} NDCs")
        return 0

    try:
        records = fetch_all()
    except (urllib.error.URLError, TimeoutError) as e:
        print(f"openFDA unreachable ({e}); seed file left unchanged.", file=sys.stderr)
        return 1

    seed = load_seed()
    built = build(records)
    # Merge: keep curated seed ingredients, let live data add/override.
    merged_ing = {**seed.get("ingredients", {}), **built["ingredients"]}
    out = {
        "version": seed.get("version", 1) + 1,
        "updated": time.strftime("%Y-%m-%d"),
        "source": "Generated from openFDA NDC Directory (dea_schedule), merged with curated seed.",
        "ingredients": dict(sorted(merged_ing.items())),
        "ndc": dict(sorted(built["ndc"].items())),
    }
    OUT.write_text(json.dumps(out, indent=2) + "\n")
    print(f"Wrote {OUT} — {len(out['ingredients'])} ingredients, {len(out['ndc'])} NDCs")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
