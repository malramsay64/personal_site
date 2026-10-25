#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Routine version and date bumps, run monthly by
.github/workflows/maintenance.yml. Each step only edits files when something
is due, so a run with nothing to do leaves the tree clean and no PR is
opened.
"""

import base64
import hashlib
import json
import os
import re
import urllib.request
from datetime import UTC, datetime, timedelta
from pathlib import Path

KATEX_FILES = ("katex.min.css", "katex.min.js", "contrib/auto-render.min.js", "contrib/copy-tex.min.js")


def bump_security_txt(today) -> None:
    sec = Path("static/.well-known/security.txt")
    text = sec.read_text()
    match = re.search(r"^Expires: (\d{4}-\d{2}-\d{2})T", text, re.MULTILINE)
    if not match:
        raise SystemExit(f"{sec}: couldn't find Expires")
    expires = datetime.strptime(match.group(1), "%Y-%m-%d").date()
    if expires < today + timedelta(days=90):
        new = today + timedelta(days=365)
        sec.write_text(re.sub(r"^Expires: .*", f"Expires: {new}T00:00:00.000Z", text, flags=re.MULTILINE))
        print(f"security.txt: Expires {expires} -> {new}")


def bump_footer_year(today) -> None:
    config = Path("config.toml")
    text = config.read_text()
    year = today.year
    if f'footer_copyright = "© 2017–{year}' not in text:
        config.write_text(re.sub(r'(footer_copyright = "© 2017–)\d{4}', rf"\g<1>{year}", text))
        print(f"footer: copyright year -> {year}")


def version_tuple(v: str) -> tuple[int, ...]:
    return tuple(int(p) for p in v.split("."))


def bump_zola() -> None:
    """Track the latest Zola release. ZOLA_LATEST can be set to skip the API call."""
    justfile = Path("justfile")
    text = justfile.read_text()
    match = re.search(r'zola_version := "(.*)"', text)
    if not match:
        raise SystemExit(f"{justfile}: couldn't find zola_version")
    current = match.group(1)
    latest = os.environ.get("ZOLA_LATEST")
    if not latest:
        headers = {}
        if token := os.environ.get("GITHUB_TOKEN"):
            headers["Authorization"] = f"Bearer {token}"
        req = urllib.request.Request("https://api.github.com/repos/getzola/zola/releases/latest", headers=headers)
        with urllib.request.urlopen(req) as resp:
            latest = json.load(resp)["tag_name"].lstrip("v")

    if latest and latest != current and version_tuple(latest) > version_tuple(current):
        justfile.write_text(re.sub(r'zola_version := ".*"', f'zola_version := "{latest}"', text))
        print(f"zola: {current} -> {latest}")


def sync_katex() -> None:
    """Re-sync the self-hosted copy under static/katex with the version
    serene's own templates pin, verifying each file against serene's own
    jsdelivr SRI hash before trusting it."""
    serene = Path("themes/serene/templates/post.html").read_text()
    ours_path = Path("templates/post.html")
    ours = ours_path.read_text()
    version_match = re.search(r"katex@([0-9.]+)/dist/katex\.min\.css", serene)
    if not version_match:
        raise SystemExit("katex: couldn't find the pinned version in serene's templates")
    version = version_match.group(1)
    changed = False
    for name in KATEX_FILES:
        base = name.rsplit("/", 1)[-1]
        match = re.search(re.escape(base) + r'"\s+integrity="([^"]+)"', serene)
        if not match:
            raise SystemExit(f"katex: couldn't read {name}'s hash from serene's templates")
        sri = match.group(1)
        with urllib.request.urlopen(f"https://cdn.jsdelivr.net/npm/katex@{version}/dist/{name}") as resp:
            content = resp.read()
        got = "sha384-" + base64.b64encode(hashlib.sha384(content).digest()).decode()
        if got != sri:
            raise SystemExit(f"katex: SRI mismatch for {name} (expected {sri}, got {got})")
        dest = Path("static/katex") / name
        if dest.exists() and dest.read_bytes() == content:
            continue
        changed = True
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(content)
        prefix = "path='katex/" + name + "') }}\" integrity=\""
        start = ours.index(prefix) + len(prefix)
        end = ours.index('"', start)
        ours = ours[:start] + sri + ours[end:]

    if changed:
        ours_path.write_text(ours)
        fonts_dir = Path("static/katex/fonts")
        for old in fonts_dir.glob("*.woff2"):
            old.unlink()
        css = (Path("static/katex") / "katex.min.css").read_text()
        for font in sorted(set(re.findall(r"fonts/([A-Za-z0-9_.-]+\.woff2)", css))):
            with urllib.request.urlopen(f"https://cdn.jsdelivr.net/npm/katex@{version}/dist/fonts/{font}") as resp:
                (fonts_dir / font).write_bytes(resp.read())
        print(f"katex: updated to {version}")
    else:
        print(f"katex: up to date ({version})")


def main() -> None:
    today = datetime.now(UTC).date()
    bump_security_txt(today)
    bump_footer_year(today)
    bump_zola()
    sync_katex()


if __name__ == "__main__":
    main()
