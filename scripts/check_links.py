#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Check links in the built site with lychee.

Usage:
  scripts/check_links.py           internal links and #anchors only (offline)
  scripts/check_links.py external  external links too

Links to the site itself are checked against public/ rather than the live
site. The project demos under /projects/<demo>/ are third-party builds and
skipped.
"""

import re
import subprocess
import sys
from pathlib import Path


def main(mode: str = "") -> None:
    match = re.search(r'^base_url = "(.*)"', Path("config.toml").read_text(), re.MULTILINE)
    if not match:
        raise SystemExit("config.toml: couldn't find base_url")
    base_url = match.group(1)
    cwd = Path.cwd()
    args = [
        "lychee",
        "--no-progress",
        "--root-dir",
        str(cwd / "public"),
        "--remap",
        f"^{re.escape(base_url)}/(.*)$ file://{cwd}/public/$1",
        "--index-files",
        "index.html",
        "--include-fragments",
        "--exclude-path",
        "public/projects",
    ]
    if mode == "external":
        # LinkedIn rejects automated requests; 429s are rate limits, not broken links.
        args += [
            "--max-retries",
            "3",
            "--accept",
            "200..=299,429",
            "--exclude",
            r"^https://(www\.)?linkedin\.com/",
        ]
    else:
        args.append("--offline")
    args.append("public/**/*.html")
    sys.exit(subprocess.run(args, check=False).returncode)


if __name__ == "__main__":
    main(*sys.argv[1:])
