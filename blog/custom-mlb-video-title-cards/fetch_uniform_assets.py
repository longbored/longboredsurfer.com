#!/usr/bin/env python3
"""
Fetch MLB batter uniform images from prod-gameday.mlbstatic.com.

Requires Python 3.10+.  No third-party dependencies.

These are the per-jersey/pants silhouette PNGs used in the Gameday pitch view.
Each PNG is a palette-indexed image rendered in the team's actual uniform colours
for that specific jersey or pants asset.

Asset codes (e.g. '119_jersey_4_2024') come from the MLB Stats API and images
are stored mirroring the CDN path:

  {output}/batters/{year}/{right|left}/{uniformAssetCode}.png

Teams are resolved dynamically from the MLB Stats API — no hard-coded ID table.

Sources (at least one required)
---------------------------------
  --game  GAMEPK ...   Fetch assets for specific game(s)
  --team  TEAM ...     Fetch current-season uniform catalog for team(s)
  --season YEAR ...    Fetch all game assets for a full season (via schedule API).
                       Note: /uniforms/team accepts a season parameter but only
                       returns data for the current season, so historical fetches
                       go through the schedule API + /uniforms/game instead.

Optional
--------
  --hand  {right,left,both}   Handedness of batter silhouette (default: both)
  --output DIR                Output root (default: ./uniform_assets)
  --dry-run                   Print what would be fetched; do not download
  --force                     Re-download even if file already exists
  --batch-size N              GamePks per uniforms/game API call (default: 50)

Examples
--------
  python fetch_uniform_assets.py --game 823231
  python fetch_uniform_assets.py --game 823231 744795 --hand right
  python fetch_uniform_assets.py --team LAD NYY
  python fetch_uniform_assets.py --team LAD --season 2024 2025
  python fetch_uniform_assets.py --season 2024
  python fetch_uniform_assets.py --season 2024 2025 --output ./assets/batters
"""

import argparse
import json
import ssl
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

IMAGE_BASE = "https://prod-gameday.mlbstatic.com/responsive-gameday-assets/1.3.0"
IMAGE_URL  = IMAGE_BASE + "/images/batters/{year}/{hand}/{code}.png"

STATSAPI_BASE     = "https://statsapi.mlb.com/api/v1"
TEAMS_URL         = STATSAPI_BASE + "/teams?sportId=1&activeStatus=Y"
UNIFORMS_GAME_URL = STATSAPI_BASE + "/uniforms/game?gamePks={gamePks}"
UNIFORMS_TEAM_URL = STATSAPI_BASE + "/uniforms/team?teamIds={teamIds}"
SCHEDULE_URL      = (STATSAPI_BASE
                     + "/schedule?sportId=1&season={season}&gameType=R"
                     + "&fields=dates,games,gamePk")

# Hat/cap assets live at a different CDN path and are not downloadable here.
SKIP_ASSET_TYPES = {"hat", "cap"}

HANDS = ("right", "left")

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
    ctx = _ssl_ctx()
    req = urllib.request.Request(url, headers={
        "User-Agent": "Mozilla/5.0",
        "Accept-Encoding": "gzip",
    })
    try:
        import gzip as gz
        with urllib.request.urlopen(req, timeout=20, context=ctx) as resp:
            raw = resp.read()
            if resp.headers.get("Content-Encoding") == "gzip":
                raw = gz.decompress(raw)
            return json.loads(raw.decode("utf-8"))
    except urllib.error.HTTPError as e:
        print(f"  HTTP {e.code}: {label or url}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"  Error fetching {label or url}: {e}", file=sys.stderr)
        return None


def _download_image(url: str, dest: Path, force=False, dry_run=False) -> str:
    """Download url to dest. Returns 'ok', 'skipped', or 'error'."""
    if dest.exists() and not force:
        return "skipped"
    if dry_run:
        print(f"  [dry-run] {dest}")
        return "ok"
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={
        "User-Agent": "Mozilla/5.0",
        "Referer": "https://www.mlb.com/",
        "Accept": "image/png,image/*;q=0.8,*/*;q=0.5",
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
    """Accept an abbreviation (e.g. 'LAD', 'lad') or numeric ID ('119')."""
    if team_arg.isdigit():
        return int(team_arg)
    needle = team_arg.upper()
    for t in _fetch_teams():
        if t["abbreviation"] == needle:
            return t["id"]
    print(f"Unknown team '{team_arg}'. Use an abbreviation (e.g. LAD, NYY) or numeric ID.",
          file=sys.stderr)
    return None


# ---------------------------------------------------------------------------
# Asset code helpers
# ---------------------------------------------------------------------------

def _year_from_code(code: str) -> str:
    """'119_jersey_4_2026' → '2026'"""
    return code.rsplit("_", 1)[-1]


def _team_id_from_code(code: str) -> int | None:
    """'119_jersey_4_2026' → 119"""
    part = code.split("_", 1)[0]
    return int(part) if part.isdigit() else None


def _asset_type(asset: dict) -> str:
    """Return 'jersey', 'pants', or 'cap' from a uniformAssets entry."""
    type_code = (asset.get("uniformAssetType") or {}).get("uniformAssetTypeCode", "")
    return {"J": "jersey", "P": "pants", "C": "cap"}.get(type_code, "")


def _extract_assets(data: dict | None) -> set[tuple[str, str]]:
    """
    Pull (uniformAssetCode, year) pairs from a /uniforms/game or /uniforms/team
    response, skipping cap/hat assets which use a different CDN path.
    """
    if not data:
        return set()
    results: set[tuple[str, str]] = set()
    for entry in data.get("uniforms", []):
        # /uniforms/game wraps assets under 'home'/'away'
        for side in ("home", "away"):
            for asset in (entry.get(side) or {}).get("uniformAssets", []):
                if _asset_type(asset) in SKIP_ASSET_TYPES:
                    continue
                code = asset.get("uniformAssetCode")
                if code:
                    results.add((code, _year_from_code(code)))
        # /uniforms/team puts assets directly under the entry
        for asset in entry.get("uniformAssets", []):
            if isinstance(asset, dict) and _asset_type(asset) not in SKIP_ASSET_TYPES:
                code = asset.get("uniformAssetCode")
                if code:
                    results.add((code, _year_from_code(code)))
    return results


# ---------------------------------------------------------------------------
# Source collectors
# ---------------------------------------------------------------------------

def assets_from_games(game_pks: list[int], batch_size: int = 50) -> set[tuple[str, str]]:
    """Fetch uniform assets for specific game PKs via /uniforms/game."""
    results: set[tuple[str, str]] = set()
    for i in range(0, len(game_pks), batch_size):
        batch = game_pks[i:i + batch_size]
        pks_str = ",".join(str(p) for p in batch)
        print(f"Fetching uniform data for {len(batch)} game(s)…")
        data = _fetch_json(UNIFORMS_GAME_URL.format(gamePks=pks_str),
                           f"gamePks={pks_str}")
        results |= _extract_assets(data)
        if i + batch_size < len(game_pks):
            time.sleep(0.3)
    return results


def assets_from_teams(team_ids: list[int]) -> set[tuple[str, str]]:
    """Fetch the current-season uniform catalog for one or more teams via /uniforms/team.

    Note: the /uniforms/team endpoint accepts a 'season' query parameter but it
    only returns data for the current season regardless of the value supplied.
    For historical seasons, use assets_from_season() which goes through the
    schedule API to collect gamePks and then calls /uniforms/game in batches.
    """
    ids_str = ",".join(str(t) for t in team_ids)
    print(f"Fetching team uniform catalog for team ID(s): {ids_str}…")
    data = _fetch_json(UNIFORMS_TEAM_URL.format(teamIds=ids_str), f"teamIds={ids_str}")
    return _extract_assets(data)


def _fetch_season_game_pks(season: int) -> list[int]:
    """Return all regular-season gamePks for the given year from the schedule API."""
    print(f"Fetching schedule for {season}…")
    data = _fetch_json(SCHEDULE_URL.format(season=season), f"schedule {season}")
    if not data:
        return []
    pks = [
        game["gamePk"]
        for date_block in data.get("dates", [])
        for game in date_block.get("games", [])
        if game.get("gamePk")
    ]
    print(f"  Found {len(pks)} games in {season}.")
    return pks


def assets_from_season(season: int, team_ids: set[int] | None = None,
                       batch_size: int = 50) -> set[tuple[str, str]]:
    """Fetch assets for all (or team-filtered) games in a season."""
    if team_ids:
        # Fetch each team's schedule entries via the schedule API with teamId filter
        all_pks: list[int] = []
        for tid in team_ids:
            url = (STATSAPI_BASE
                   + f"/schedule?sportId=1&season={season}&gameType=R"
                   + f"&teamId={tid}&fields=dates,games,gamePk")
            data = _fetch_json(url, f"schedule {season} team {tid}")
            if data:
                pks = [
                    game["gamePk"]
                    for date_block in data.get("dates", [])
                    for game in date_block.get("games", [])
                    if game.get("gamePk")
                ]
                all_pks.extend(pks)
        # De-duplicate across teams
        game_pks = list(dict.fromkeys(all_pks))
        qualifier = f" featuring team(s) {sorted(team_ids)}"
    else:
        game_pks = _fetch_season_game_pks(season)
        qualifier = ""

    if not game_pks:
        return set()
    print(f"{len(game_pks)} game(s){qualifier} in {season}.")
    return assets_from_games(game_pks, batch_size=batch_size)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(
        description="Fetch MLB batter uniform silhouette PNGs from prod-gameday.mlbstatic.com.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    ap.add_argument("--game", nargs="+", metavar="GAMEPK",
                    help="One or more gamePk values")
    ap.add_argument("--team", nargs="+", metavar="TEAM",
                    help="Team abbreviation(s) or numeric ID(s); "
                         "fetches the current-season catalog via /uniforms/team. "
                         "Combine with --season to scope to a specific year.")
    ap.add_argument("--season", nargs="+", type=int, metavar="YEAR",
                    help="Season year(s); fetches all games via the schedule API")
    ap.add_argument("--hand", choices=["right", "left", "both"], default="both",
                    help="Batter handedness (default: both)")
    ap.add_argument("--output", default="uniform_assets", metavar="DIR",
                    help="Output root directory (default: ./uniform_assets)")
    ap.add_argument("--dry-run", action="store_true",
                    help="Print paths without downloading")
    ap.add_argument("--force", action="store_true",
                    help="Re-download even if file already exists")
    ap.add_argument("--batch-size", type=int, default=50, metavar="N",
                    help="GamePks per uniforms/game API call (default: 50)")
    args = ap.parse_args()

    if not any([args.game, args.team, args.season]):
        ap.error("Provide at least one of --game, --team, or --season.")

    hands = HANDS if args.hand == "both" else (args.hand,)
    output_root = Path(args.output)
    assets: set[tuple[str, str]] = set()

    # Resolve team IDs once (needed for both --team and filtered --season)
    team_ids_resolved: list[int] = []
    if args.team:
        team_ids_resolved = [_resolve_team_id(t) for t in args.team]
        team_ids_resolved = [t for t in team_ids_resolved if t is not None]

    if args.game:
        game_pks = [int(g) for g in args.game]
        assets |= assets_from_games(game_pks, batch_size=args.batch_size)

    if args.team and not args.season:
        # No season specified: use the current-season team catalog
        if team_ids_resolved:
            assets |= assets_from_teams(team_ids_resolved)

    if args.season:
        team_id_set = set(team_ids_resolved) if team_ids_resolved else None
        for season in args.season:
            assets |= assets_from_season(season, team_ids=team_id_set,
                                         batch_size=args.batch_size)
        # If --team was given with --season, keep only assets for those teams
        if team_id_set:
            assets = {(c, y) for c, y in assets
                      if _team_id_from_code(c) in team_id_set}

    if not assets:
        print("No asset codes found. Nothing to download.")
        return

    sorted_assets = sorted(assets, key=lambda x: (x[1], x[0]))
    total = len(sorted_assets) * len(hands)
    print(f"\n{len(sorted_assets)} unique asset codes × {len(hands)} hand(s) "
          f"= {total} image(s) to fetch.")
    print(f"Output: {output_root}\n")

    counts = {"ok": 0, "skipped": 0, "error": 0}
    for code, year in sorted_assets:
        for hand in hands:
            url  = IMAGE_URL.format(year=year, hand=hand, code=code)
            dest = output_root / "batters" / year / hand / f"{code}.png"
            status = _download_image(url, dest, force=args.force, dry_run=args.dry_run)
            counts[status] += 1
            if status == "ok" and not args.dry_run:
                print(f"  ✓ {dest.relative_to(output_root)}")
            elif status == "error":
                print(f"  ✗ {code} ({hand})")

    print(f"\nDone. {counts['ok']} downloaded, {counts['skipped']} skipped, "
          f"{counts['error']} errors.")


if __name__ == "__main__":
    main()
