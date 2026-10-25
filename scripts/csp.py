#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Fill in the Content-Security-Policy in a built site's _headers.

Usage: scripts/csp.py [public]

Allows only the site's own origin, plus the hash of each inline <script>,
<style> and style="" attribute in the built pages, so no 'unsafe-inline' is
needed. Run after every `zola build` (`just build` does this).
"""

import base64
import hashlib
import html
import re
import sys
from pathlib import Path

PLACEHOLDER = "__CSP__"

# serene's image zoom (Lightense) adds <style> elements from JavaScript, which
# the scan of the HTML can't see: one on page load and one when an image is
# opened. Their text is fixed for a given lightense.min.js and the options
# main.js passes it, so their hashes are pinned here, and the build fails if
# either file changes so the hashes can't silently go stale.
LIGHTENSE_JS = Path("themes/serene/static/js/lightense.min.js")
LIGHTENSE_JS_SHA256 = "1a93457764b6482b96905d8a4074666a48137748647b25577236a33d9b3ee91c"
LIGHTENSE_CALL = 'Lightense(".prose img:not(.no-lightense)", { background: \'rgba(43, 43, 43, 0.19)\' })'
LIGHTENSE_STYLE_HASHES = [
    "'sha256-gw971OzQPqAnA8TGTCeKhjGffRPub57XHlDXPPBcz7Q='",  # lightense-images-css
    "'sha256-ioCnRf64BxuT+uRkvrWEA/LtND8b7oRxsT8wGYcm6Pk='",  # lightense-images-css-computed
]

INLINE_SCRIPT = re.compile(r"<script\b(?![^>]*\bsrc=)[^>]*>(.*?)</script>", re.DOTALL | re.IGNORECASE)
INLINE_STYLE = re.compile(r"<style\b[^>]*>(.*?)</style>", re.DOTALL | re.IGNORECASE)
STYLE_ATTR = re.compile(r"""\sstyle=(?:"([^"]*)"|'([^']*)')""", re.IGNORECASE)


def digest(text: str) -> str:
    return "'sha256-" + base64.b64encode(hashlib.sha256(text.encode()).digest()).decode() + "'"


def lightense_hashes() -> list[str]:
    actual = hashlib.sha256(LIGHTENSE_JS.read_bytes()).hexdigest()
    main_js = LIGHTENSE_JS.with_name("main.js").read_text(encoding="utf-8")
    if actual != LIGHTENSE_JS_SHA256 or LIGHTENSE_CALL not in main_js:
        sys.exit(
            "serene's Lightense script or its options changed, so the CSP hashes for "
            "its injected styles may be stale. Recompute them (open an image on a "
            "post with the CSP applied; Chrome's console error gives the expected "
            "hash) and update LIGHTENSE_* in scripts/csp.py."
        )
    return LIGHTENSE_STYLE_HASHES


def demos(public: Path) -> list[str]:
    """The project demos: third-party builds under /projects/<demo>/."""
    return [p.name for p in (public / "projects").iterdir() if p.is_dir()]


def pages(public: Path):
    skip = {("projects", demo) for demo in demos(public)}
    for path in public.rglob("*.html"):
        if path.relative_to(public).parts[:2] not in skip:
            yield path


def main(public: str = "public") -> None:
    public_path = Path(public)
    scripts, styles = set(), set(lightense_hashes())
    for path in pages(public_path):
        text = path.read_text(encoding="utf-8")
        scripts.update(digest(m.group(1)) for m in INLINE_SCRIPT.finditer(text))
        styles.update(digest(m.group(1)) for m in INLINE_STYLE.finditer(text))
        styles.update(digest(html.unescape(a or b)) for a, b in STYLE_ATTR.findall(text))

    csp = "; ".join(
        [
            "default-src 'self'",
            " ".join(["script-src 'self'", *sorted(scripts)]),
            # 'unsafe-hashes' lets the hashes cover style="" attributes too.
            " ".join(["style-src 'self' 'unsafe-hashes'", *sorted(styles)]),
            "img-src 'self' data:",
            "font-src 'self'",
            "frame-src https://www.youtube-nocookie.com",
            "connect-src 'self'",
            "object-src 'none'",
            "base-uri 'self'",
            "form-action 'self'",
            "frame-ancestors 'none'",
        ]
    )

    headers = public_path / "_headers"
    text = headers.read_text(encoding="utf-8")
    if PLACEHOLDER not in text:
        sys.exit(f"{headers}: no {PLACEHOLDER} placeholder (already filled in?)")
    text = text.replace(PLACEHOLDER, csp)
    # The demos run third-party code that this policy would block.
    for demo in sorted(demos(public_path)):
        text += f"\n/projects/{demo}/*\n  ! Content-Security-Policy\n"
    headers.write_text(text, encoding="utf-8")
    print(f"CSP: {len(scripts)} inline script hash(es), {len(styles)} inline style hash(es)")


if __name__ == "__main__":
    main(*sys.argv[1:])
