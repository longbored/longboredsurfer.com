#!/usr/bin/env python3
"""
Extract dominant fabric colors from batter silhouette PNGs.

Requires Python 3.10+.  Third-party dependency: Pillow (pip install Pillow).

Reads PNG files produced by fetch_uniform_assets.py (indexed-color PNGs from
prod-gameday.mlbstatic.com) and returns one representative hex color per
jersey or pants asset.

Asset descriptions are looked up from the MLB Stats API (/uniforms/team) for
all team IDs found in the PNG directory; older assets not in the current
season's catalog will have an empty description field.

Algorithm
---------
1. Sample only the central 40 % of pixel columns to avoid side stripes.
2. For jersey files: skip the top 35 % of the figure (head / helmet / skin).
   For pants files:  skip the top 10 % (belt) and bottom 15 % (shoes).
3. Classify each opaque pixel as neutral (HSV saturation < 0.15) or chromatic.
4. Majority vote:
   - Neutral ≥ chromatic → grey / white / cream fabric:
       return the 75th-percentile brightness pixel.
   - Otherwise → coloured fabric:
       find the dominant 30-degree hue bucket, then return the most-common
       16-step quantised colour in that cluster.

Caveats
-------
- Colours are rendered with 3-D shading, so chromatic results skew darker
  than the actual fabric (e.g. Dodger Blue #002F6C renders near #002040).
- City-Connect jerseys with large contrasting lettering in the centre may
  return the lettering colour rather than the body colour.
- Hat / cap assets are not processed here; see fetch_team_logos.py for
  team-cap-on-light SVGs as an alternative colour source for caps.

Usage
-----
  # Scan all PNGs under ./uniform_assets/batters (default), print JSON
  python extract_uniform_colors.py

  # Restrict to specific teams or seasons
  python extract_uniform_colors.py --team LAD NYY --season 2024 2025

  # Write pretty-printed JSON to a file
  python extract_uniform_colors.py --out uniform_colors.json --pretty

  # Explicit batter directory (e.g. if fetch_uniform_assets used --output)
  python extract_uniform_colors.py --batter-dir ./assets/batters
"""

import argparse
import collections
import colorsys
import gzip
import json
import ssl
import sys
import urllib.error
import urllib.request
from pathlib import Path

STATSAPI_BASE     = "https://statsapi.mlb.com/api/v1"
TEAMS_URL         = STATSAPI_BASE + "/teams?sportId=1&activeStatus=Y"
UNIFORMS_TEAM_URL = STATSAPI_BASE + "/uniforms/team?teamIds={teamIds}"

_teams_cache: list[dict] | None = None


# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------

def _ssl_ctx():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


def _fetch_json(url: str, label: str = "") -> dict | None:
    req = urllib.request.Request(url, headers={
        "User-Agent": "Mozilla/5.0",
        "Accept-Encoding": "gzip",
    })
    try:
        with urllib.request.urlopen(req, timeout=20, context=_ssl_ctx()) as resp:
            raw = resp.read()
            if resp.headers.get("Content-Encoding") == "gzip":
                raw = gzip.decompress(raw)
            return json.loads(raw.decode("utf-8"))
    except urllib.error.HTTPError as e:
        print(f"  HTTP {e.code}: {label or url}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"  Error fetching {label or url}: {e}", file=sys.stderr)
        return None


# ---------------------------------------------------------------------------
# Teams API
# ---------------------------------------------------------------------------

def _fetch_teams() -> list[dict]:
    """Return active MLB teams from the Stats API (cached for the process lifetime)."""
    global _teams_cache
    if _teams_cache is not None:
        return _teams_cache
    data = _fetch_json(TEAMS_URL, "teams list")
    if not data:
        sys.exit("Could not fetch team list from the MLB Stats API.")
    _teams_cache = [
        {
            "id": t["id"],
            "abbreviation": t.get("abbreviation", "").upper(),
            "name": t.get("name", ""),
        }
        for t in data.get("teams", [])
        if t.get("id") and t.get("sport", {}).get("id") == 1
    ]
    return _teams_cache


def _resolve_team_id(team_arg: str) -> int | None:
    """Accept a team abbreviation (e.g. 'LAD') or numeric ID ('119')."""
    if team_arg.isdigit():
        return int(team_arg)
    needle = team_arg.upper()
    for t in _fetch_teams():
        if t["abbreviation"] == needle:
            return t["id"]
    print(f"Unknown team '{team_arg}'. Use an abbreviation (e.g. LAD, NYY) or numeric ID.",
          file=sys.stderr)
    return None


def _fetch_descriptions(team_ids: set[int]) -> dict[str, str]:
    """
    Return {uniformAssetCode: uniformAssetText} for the given team IDs by
    calling /uniforms/team.  Only current-season assets are returned by the
    API; older codes will be absent and will have an empty description.
    """
    if not team_ids:
        return {}
    ids_str = ",".join(str(t) for t in sorted(team_ids))
    data = _fetch_json(UNIFORMS_TEAM_URL.format(teamIds=ids_str),
                       f"uniform descriptions for team(s) {ids_str}")
    if not data:
        return {}
    mapping: dict[str, str] = {}
    for entry in data.get("uniforms", []):
        for asset in entry.get("uniformAssets", []):
            code = asset.get("uniformAssetCode")
            text = asset.get("uniformAssetText")
            if code and text:
                mapping[code] = text
    return mapping


# ---------------------------------------------------------------------------
# Image helpers
# ---------------------------------------------------------------------------

def _figure_bounds(img):
    """Return (top_row, bottom_row) of opaque pixels, sampling every 4th column."""
    top = bottom = None
    for y in range(img.height):
        if any(img.getpixel((x, y))[3] > 80 for x in range(0, img.width, 4)):
            if top is None:
                top = y
            bottom = y
    return (top or 0), (bottom or img.height - 1)


def extract_fabric_color(path: Path, kind: str) -> str:
    """
    Return a hex colour string (#RRGGBB) for the dominant fabric colour.

    Parameters
    ----------
    path : Path   PNG file (jersey or pants layer from a batter silhouette).
    kind : str    'jersey' or 'pants'.
    """
    try:
        from PIL import Image
    except ImportError:
        sys.exit("Pillow is required: pip install Pillow")

    img = Image.open(path).convert("RGBA")
    w = img.width
    top, bottom = _figure_bounds(img)
    fig_h = bottom - top

    if kind == "jersey":
        y0 = top + int(fig_h * 0.35)      # skip head / helmet
        y1 = bottom
    else:
        y0 = top + int(fig_h * 0.10)      # skip belt
        y1 = bottom - int(fig_h * 0.15)   # skip shoes

    # Central 40 % of columns — avoids side stripes and outseam piping
    x0, x1 = w * 3 // 10, w * 7 // 10

    pixels_hsv = []
    for y in range(y0, y1 + 1):
        for x in range(x0, x1):
            r, g, b, a = img.getpixel((x, y))
            if a > 80:
                h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
                pixels_hsv.append((h, s, v, r, g, b))

    if not pixels_hsv:
        return "#000000"

    neutral   = [p for p in pixels_hsv if p[1] < 0.15]
    chromatic = [p for p in pixels_hsv if p[1] >= 0.15]

    if len(neutral) >= len(chromatic):
        # Neutral fabric (white / grey / cream): 75th-percentile brightness
        by_val = sorted(neutral, key=lambda p: p[2])
        p = by_val[3 * len(by_val) // 4]
        return f"#{p[3]:02X}{p[4]:02X}{p[5]:02X}"
    else:
        # Chromatic fabric: dominant 30° hue cluster → most-common 16-step colour
        bkt = 1 / 12
        hue_ctr = collections.Counter(int(p[0] / bkt) for p in chromatic)
        top_bkt = hue_ctr.most_common(1)[0][0]
        cluster = [p for p in chromatic if int(p[0] / bkt) == top_bkt]
        q_ctr = collections.Counter(
            (r // 16 * 16, g // 16 * 16, b // 16 * 16)
            for _, _, _, r, g, b in cluster
        )
        r, g, b = q_ctr.most_common(1)[0][0]
        return f"#{r:02X}{g:02X}{b:02X}"


# ---------------------------------------------------------------------------
# Directory scan
# ---------------------------------------------------------------------------

def scan(batter_dir: Path, team_ids: set[int] | None,
         seasons: set[str] | None) -> dict:
    """
    Walk batter_dir/{season}/{hand}/{code}.png and extract one colour per file.
    The right-hand subdirectory is preferred; left is used as a fallback so the
    script works even when fetch_uniform_assets.py was run with --hand left.
    Both hands render identical colours, so only one set is processed to avoid
    duplicate entries.

    Returns a dict keyed by uniformAssetCode:
      {"color": "#RRGGBB", "kind": "jersey"|"pants",
       "description": str, "season": str, "team_id": int}
    """
    if not batter_dir.is_dir():
        sys.exit(f"Batter directory not found: {batter_dir}\n"
                 "Run fetch_uniform_assets.py first, then point --batter-dir at "
                 "its output/batters folder.")

    # First pass: collect codes and discover which team IDs are present
    entries: list[tuple[Path, str, str, str]] = []  # (path, code, kind, season)
    found_team_ids: set[int] = set()

    for season_dir in sorted(batter_dir.iterdir()):
        if not season_dir.is_dir():
            continue
        season = season_dir.name
        if seasons and season not in seasons:
            continue

        # Prefer right-hand silhouettes; fall back to left if right is absent.
        hand_dir = next(
            (season_dir / h for h in ("right", "left") if (season_dir / h).is_dir()),
            None,
        )
        if hand_dir is None:
            continue

        for png in sorted(hand_dir.iterdir()):
            if png.suffix.lower() != ".png":
                continue
            code = png.stem                     # e.g. 119_jersey_4_2024
            parts = code.split("_")
            if len(parts) < 4 or not parts[0].isdigit():
                continue

            tid = int(parts[0])
            if team_ids and tid not in team_ids:
                continue

            if "_jersey_" in code:
                kind = "jersey"
            elif "_pants_" in code:
                kind = "pants"
            else:
                continue    # hat/cap — not handled here

            found_team_ids.add(tid)
            entries.append((png, code, kind, season))

    if not entries:
        return {}

    # Fetch descriptions for all discovered teams in one API call
    descriptions = _fetch_descriptions(found_team_ids)

    # Second pass: extract colours
    results: dict = {}
    for png, code, kind, season in entries:
        try:
            color = extract_fabric_color(png, kind)
        except Exception as e:
            print(f"  Warning: {png.name}: {e}", file=sys.stderr)
            continue

        results[code] = {
            "color":       color,
            "kind":        kind,
            "description": descriptions.get(code, ""),
            "season":      season,
            "team_id":     int(code.split("_")[0]),
        }

    return results


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(
        description="Extract dominant fabric hex colors from batter silhouette PNGs.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    ap.add_argument("--batter-dir", type=Path,
                    default=Path("uniform_assets") / "batters", metavar="DIR",
                    help="Root of downloaded batter PNGs "
                         "(default: ./uniform_assets/batters — matches the default "
                         "output of fetch_uniform_assets.py)")
    ap.add_argument("--team", nargs="+", metavar="TEAM",
                    help="Restrict to team abbreviation(s) (e.g. LAD NYY) or numeric IDs")
    ap.add_argument("--season", nargs="+", metavar="YEAR",
                    help="Restrict to season year(s) (e.g. 2024 2025)")
    ap.add_argument("--out", type=Path, metavar="FILE",
                    help="Write JSON to FILE instead of stdout")
    ap.add_argument("--pretty", action="store_true",
                    help="Pretty-print JSON output")
    args = ap.parse_args()

    team_ids: set[int] | None = None
    if args.team:
        resolved = [_resolve_team_id(t) for t in args.team]
        team_ids = {t for t in resolved if t is not None}
        if not team_ids:
            ap.error("No valid teams specified. Use abbreviations (e.g. LAD NYY) or numeric IDs.")

    seasons = set(args.season) if args.season else None

    results = scan(args.batter_dir, team_ids, seasons)

    indent = 2 if args.pretty else None
    json_str = json.dumps(results, indent=indent, sort_keys=True)

    if args.out:
        args.out.write_text(json_str, encoding="utf-8")
        print(f"Wrote {len(results)} entries to {args.out}", file=sys.stderr)
    else:
        print(json_str)


if __name__ == "__main__":
    main()
