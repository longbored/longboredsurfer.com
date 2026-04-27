#!/usr/bin/env python3
"""
Fetch MLB team logo SVGs from www.mlbstatic.com.

Requires Python 3.10+.  No third-party dependencies.

Teams are discovered dynamically from the MLB Stats API
(https://statsapi.mlb.com/api/v1/teams) so no hard-coded ID table is needed.
Pass --season to target a specific year's roster of teams; omit it for the
current season.

Available variants
------------------
  team-cap-on-light       Cap logo, light-background version (coloured)
  team-cap-on-dark        Cap logo, dark-background version (white fill)
  team-primary-on-light   Primary logo, light background
  team-primary-on-dark    Primary logo, dark background
  team-wordmark-on-light  Wordmark (text) logo, light background
  team-wordmark-on-dark   Wordmark (text) logo, dark background
  team-spot               Circle/roundel logo with team brand colour fill
  base                    Hat-only logo (no subfolder in the URL)

Files are stored mirroring the URL structure:
  {output}/{variant}/{teamId}.svg
  {output}/base/{teamId}.svg   (for the base variant)

Examples
--------
  python fetch_team_logos.py
  python fetch_team_logos.py --team LAD NYY --variant team-cap-on-light
  python fetch_team_logos.py --variant team-primary-on-light --dry-run
  python fetch_team_logos.py --team 119 --force
  python fetch_team_logos.py --season 2024
"""

import argparse
import gzip
import json
import ssl
import sys
import urllib.error
import urllib.request
from pathlib import Path

STATSAPI_BASE = "https://statsapi.mlb.com/api/v1"
LOGO_BASE     = "https://www.mlbstatic.com/team-logos"
TEAMS_URL     = STATSAPI_BASE + "/teams?sportId=1&activeStatus=Y"

VARIANTS = [
    "team-cap-on-light",
    "team-cap-on-dark",
    "team-primary-on-light",
    "team-primary-on-dark",
    "team-wordmark-on-light",
    "team-wordmark-on-dark",
    "team-spot",
    "base",
]

# Module-level cache so we only call the API once per run.
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


def _download_svg(url: str, dest: Path, force=False, dry_run=False) -> str:
    """Download url to dest. Returns 'ok', 'skipped', or 'error'."""
    if dest.exists() and not force:
        return "skipped"
    if dry_run:
        print(f"  [dry-run] {dest}")
        return "ok"
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={
        "User-Agent": "Mozilla/5.0",
        "Accept": "image/svg+xml,image/*;q=0.8,*/*;q=0.5",
        "Referer": "https://www.mlb.com/",
    })
    try:
        with urllib.request.urlopen(req, timeout=20, context=_ssl_ctx()) as resp:
            dest.write_bytes(resp.read())
        return "ok"
    except urllib.error.HTTPError as e:
        print(f"  HTTP {e.code}: {url}", file=sys.stderr)
        return "error"
    except Exception as e:
        print(f"  Error: {url}: {e}", file=sys.stderr)
        return "error"


# ---------------------------------------------------------------------------
# Teams API
# ---------------------------------------------------------------------------

def _fetch_teams(season: int | None = None) -> list[dict]:
    """
    Return a list of active MLB teams from the Stats API.
    Each entry has 'id', 'abbreviation', and 'name'.
    Results are cached for the lifetime of the process.
    """
    global _teams_cache
    if _teams_cache is not None:
        return _teams_cache

    url = TEAMS_URL
    if season:
        url += f"&season={season}"
    data = _fetch_json(url, "teams list")
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


def _resolve_team_id(team_arg: str, season: int | None = None) -> int | None:
    """
    Accept a team abbreviation (e.g. 'LAD', 'lad') or numeric ID ('119').
    Looks up abbreviations dynamically from the MLB Stats API.
    """
    if team_arg.isdigit():
        return int(team_arg)
    needle = team_arg.upper()
    for t in _fetch_teams(season):
        if t["abbreviation"] == needle:
            return t["id"]
    print(f"Unknown team '{team_arg}'. Use an abbreviation (e.g. LAD, NYY) or numeric ID.",
          file=sys.stderr)
    return None


def _logo_url(team_id: int, variant: str) -> str:
    if variant == "base":
        return f"{LOGO_BASE}/{team_id}.svg"
    return f"{LOGO_BASE}/{variant}/{team_id}.svg"


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(
        description="Fetch MLB team logo SVGs from www.mlbstatic.com.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    ap.add_argument("--team", nargs="+", metavar="TEAM",
                    help="Team abbreviation(s) or numeric ID(s) (default: all active teams)")
    ap.add_argument("--variant", nargs="+", metavar="VARIANT",
                    choices=VARIANTS, dest="variants",
                    help=f"Logo variant(s) to fetch (default: all). "
                         f"Choices: {', '.join(VARIANTS)}")
    ap.add_argument("--season", type=int, metavar="YEAR",
                    help="Season year used to look up teams (default: current season)")
    ap.add_argument("--output", default="team_logos", metavar="DIR",
                    help="Output root directory (default: ./team_logos)")
    ap.add_argument("--dry-run", action="store_true",
                    help="Print paths without downloading")
    ap.add_argument("--force", action="store_true",
                    help="Re-download even if file already exists")
    args = ap.parse_args()

    # Resolve teams
    if args.team:
        team_ids = [_resolve_team_id(t, args.season) for t in args.team]
        team_ids = [t for t in team_ids if t is not None]
        if not team_ids:
            ap.error("No valid teams specified.")
    else:
        team_ids = sorted(t["id"] for t in _fetch_teams(args.season))

    variants = args.variants or VARIANTS
    output_root = Path(args.output)

    total = len(team_ids) * len(variants)
    print(f"{len(team_ids)} team(s) × {len(variants)} variant(s) = {total} SVG(s) to fetch.")
    print(f"Output: {output_root}\n")

    counts = {"ok": 0, "skipped": 0, "error": 0}
    for variant in variants:
        for team_id in sorted(team_ids):
            url  = _logo_url(team_id, variant)
            dest = output_root / (variant if variant != "base" else "base") / f"{team_id}.svg"
            status = _download_svg(url, dest, force=args.force, dry_run=args.dry_run)
            counts[status] += 1
            if status == "ok" and not args.dry_run:
                print(f"  ✓ {dest.relative_to(output_root)}")
            elif status == "error":
                print(f"  ✗ {team_id} / {variant}")

    print(f"\nDone. {counts['ok']} downloaded, {counts['skipped']} skipped, "
          f"{counts['error']} errors.")


if __name__ == "__main__":
    main()
