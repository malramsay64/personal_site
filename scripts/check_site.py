"""Sanity checks on the built site: sitemap, feed and robots.txt.

Usage: python3 scripts/check_site.py [public]

Checks that every page is in the sitemap and every sitemap URL exists, that the
blog feed is valid Atom with one entry per post, and that robots.txt points at
the sitemap. Prints GitHub Actions error annotations and exits non-zero on failure.
"""

import sys
import tomllib
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path

ATOM = "{http://www.w3.org/2005/Atom}"
SITEMAP = "{http://www.sitemaps.org/schemas/sitemap/0.9}"

errors = []


def error(message):
    errors.append(message)
    print(f"::error::{message}")


def url_to_path(public, base_url, url):
    if not url.startswith(base_url):
        return None
    path = public / url[len(base_url) :].lstrip("/")
    return path / "index.html" if url.endswith("/") or path.is_dir() else path


def parse(path):
    try:
        return ET.parse(path).getroot()
    except (ET.ParseError, FileNotFoundError) as e:
        error(f"{path}: {e}")
        return None


def check_sitemap(public, base_url):
    root = parse(public / "sitemap.xml")
    if root is None:
        return
    urls = [loc.text.strip() for loc in root.iter(f"{SITEMAP}loc")]
    for url in urls:
        path = url_to_path(public, base_url, url)
        if path is None or not path.exists():
            error(f"sitemap.xml lists {url}, which isn't in the built site")
    listed = {url_to_path(public, base_url, u) for u in urls}
    for section in ("post", "talks", "publication"):
        for page in (public / section).glob("*/index.html"):
            if page.parent.name != "page" and page not in listed:
                error(f"{page.relative_to(public)} is missing from sitemap.xml")
    print(f"sitemap.xml: {len(urls)} URLs")


def check_feed(public, base_url):
    feed = public / "post" / "feed.xml"
    root = parse(feed)
    if root is None:
        return
    if root.tag != f"{ATOM}feed":
        error(f"{feed}: root element is {root.tag}, expected an Atom feed")
        return
    entries = root.findall(f"{ATOM}entry")
    posts = [p for p in (public / "post").glob("*/index.html") if p.parent.name != "page"]
    if len(entries) != len(posts):
        error(f"{feed}: {len(entries)} entries but {len(posts)} posts")
    for entry in entries:
        title = entry.findtext(f"{ATOM}title", "").strip()
        link = entry.find(f"{ATOM}link")
        href = link.get("href", "") if link is not None else ""
        if not title:
            error(f"{feed}: entry without a title ({href})")
        path = url_to_path(public, base_url, href)
        if path is None or not path.exists():
            error(f"{feed}: entry '{title}' links to {href}, which isn't in the built site")
        for tag in ("updated", "published"):
            value = entry.findtext(f"{ATOM}{tag}")
            if value is not None:
                try:
                    datetime.fromisoformat(value)
                except ValueError:
                    error(f"{feed}: entry '{title}' has an invalid {tag} date {value!r}")
    print(f"feed.xml: {len(entries)} entries")


def check_robots(public, base_url):
    robots = (public / "robots.txt").read_text()
    if f"Sitemap: {base_url}/sitemap.xml" not in robots:
        error("robots.txt doesn't point at the sitemap")


def main(public="public"):
    public = Path(public)
    with open("config.toml", "rb") as f:
        base_url = tomllib.load(f)["base_url"].rstrip("/")
    check_sitemap(public, base_url)
    check_feed(public, base_url)
    check_robots(public, base_url)
    if errors:
        sys.exit(f"{len(errors)} problem(s) found")
    print("Site checks passed")


if __name__ == "__main__":
    main(*sys.argv[1:])
