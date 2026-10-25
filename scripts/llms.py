#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Mirror each post/talk/publication as raw Markdown, and write an llms.txt index.

Usage: scripts/llms.py [public]

Pages are found by their zola-source <meta> tag (set in templates/post.html),
which names the content file relative to content/ that rendered them. Only
pages using that template (post, talks and publication entries) carry the
tag, so section listings and the home page are skipped automatically.
"""

import re
import sys
import tomllib
from pathlib import Path

SOURCE_META = re.compile(r'<meta name="zola-source" content="([^"]+)">')


def front_matter(text: str) -> tuple[dict, str]:
    if not text.startswith("+++"):
        return {}, text
    end = text.index("\n+++", 3)
    front = tomllib.loads(text[3:end])
    return front, text[end + 4 :].lstrip("\n")


def main(public: str = "public") -> None:
    public_path = Path(public)
    with open("config.toml", "rb") as f:
        site = tomllib.load(f)
    base_url = site["base_url"].rstrip("/")

    sections: dict[str, list[tuple]] = {}
    for html_path in sorted(public_path.rglob("index.html")):
        match = SOURCE_META.search(html_path.read_text(encoding="utf-8"))
        if not match:
            continue
        src = Path("content") / match.group(1)
        front, body = front_matter(src.read_text(encoding="utf-8"))
        (html_path.parent / "index.md").write_text(body, encoding="utf-8")

        section = match.group(1).split("/", 1)[0]
        url = f"{base_url}/{html_path.parent.relative_to(public_path)}/"
        sections.setdefault(section, []).append(
            (front.get("date"), front.get("title", ""), front.get("description", ""), url)
        )

    lines = [f"# {site['title']}", "", f"> {site['description']}", ""]
    for section in ("post", "talks", "publication"):
        entries = sections.get(section)
        if not entries:
            continue
        lines += [f"## {section.capitalize()}", ""]
        for _, title, description, url in sorted(entries, reverse=True):
            entry = f"- [{title}]({url})"
            if description:
                entry += f": {description}"
            lines.append(entry)
        lines.append("")
    (public_path / "llms.txt").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

    mirrored = sum(len(v) for v in sections.values())
    print(f"llms: mirrored {mirrored} page(s) as Markdown, wrote llms.txt")


if __name__ == "__main__":
    main(*sys.argv[1:])
