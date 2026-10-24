# Commands for building and checking the site, and for maintaining it.
# CI runs these same recipes, so local runs and CI can't drift apart. Every
# script this repo needs lives here rather than in a separate scripts/ dir.
#
# Needs zola (zola_version below) and uv (runs the Python recipes below, and
# zizmor), plus for the checks: lychee, harper-cli, jq, and npx with Chrome
# (Lighthouse, Wrangler).

set positional-arguments

# Bumped monthly by the `maintenance` recipe below; CI installs this version.
zola_version := "0.23.6"
zizmor_version := "1.31.1"
lhci_version := "0.15.1"
wrangler_version := "4.151.1"
wrangler := "npx --yes wrangler@" + wrangler_version
worker := "malramsay-com"

# List recipes
default:
    @just --list

# Build the site into public/ and fill in its CSP; extra args go to zola build
build *args:
    @zola --version | grep -qx "zola {{ zola_version }}" || echo "warning: expected zola {{ zola_version }}, found $(zola --version)" >&2
    zola build "$@"
    just csp

# Serve the site locally with live reload
serve:
    zola serve

# Checks run by the CI build on every push
ci: build check-site links check-security-txt

# Everything in `ci`, plus zizmor
check: ci zizmor

# Fill in the Content-Security-Policy in a built site's _headers (run after every `zola build`)
csp public="public":
    #!/usr/bin/env -S uv run --script
    # /// script
    # requires-python = ">=3.11"
    # dependencies = []
    # ///
    # Allows only the site's own origin, plus the hash of each inline
    # <script>, <style> and style="" attribute in the built pages, so no
    # 'unsafe-inline' is needed.
    import base64, hashlib, html, re, sys
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

    INLINE_SCRIPT = re.compile(r"<script\b(?![^>]*\bsrc=)[^>]*>(.*?)</script>", re.S | re.I)
    INLINE_STYLE = re.compile(r"<style\b[^>]*>(.*?)</style>", re.S | re.I)
    STYLE_ATTR = re.compile(r"""\sstyle=(?:"([^"]*)"|'([^']*)')""", re.I)

    def digest(text):
        return "'sha256-" + base64.b64encode(hashlib.sha256(text.encode()).digest()).decode() + "'"

    def lightense_hashes():
        actual = hashlib.sha256(LIGHTENSE_JS.read_bytes()).hexdigest()
        main_js = LIGHTENSE_JS.with_name("main.js").read_text(encoding="utf-8")
        if actual != LIGHTENSE_JS_SHA256 or LIGHTENSE_CALL not in main_js:
            sys.exit(
                "serene's Lightense script or its options changed, so the CSP hashes for "
                "its injected styles may be stale. Recompute them (open an image on a "
                "post with the CSP applied; Chrome's console error gives the expected "
                "hash) and update LIGHTENSE_* in the `csp` recipe in justfile."
            )
        return LIGHTENSE_STYLE_HASHES

    def demos(public):
        """The project demos: third-party builds under /projects/<demo>/."""
        return [p.name for p in (public / "projects").iterdir() if p.is_dir()]

    def pages(public):
        skip = {("projects", demo) for demo in demos(public)}
        for path in public.rglob("*.html"):
            if path.relative_to(public).parts[:2] not in skip:
                yield path

    def main(public="public"):
        public = Path(public)
        scripts, styles = set(), set(lightense_hashes())
        for path in pages(public):
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

        headers = public / "_headers"
        text = headers.read_text(encoding="utf-8")
        if PLACEHOLDER not in text:
            sys.exit(f"{headers}: no {PLACEHOLDER} placeholder (already filled in?)")
        text = text.replace(PLACEHOLDER, csp)
        # The demos run third-party code that this policy would block.
        for demo in sorted(demos(public)):
            text += f"\n/projects/{demo}/*\n  ! Content-Security-Policy\n"
        headers.write_text(text, encoding="utf-8")
        print(f"CSP: {len(scripts)} inline script hash(es), {len(styles)} inline style hash(es)")

    main("{{ public }}")

# Sanity checks on a built site: sitemap, feed, robots.txt and assets
check-site public="public":
    #!/usr/bin/env -S uv run --script
    # /// script
    # requires-python = ">=3.11"
    # dependencies = []
    # ///
    # Checks that every page is in the sitemap and every sitemap URL exists,
    # that the blog feed is valid Atom with one entry per post, that
    # robots.txt points at the sitemap, and that pages only load scripts and
    # styles from the site itself (as the CSP requires).
    import re, sys, tomllib, xml.etree.ElementTree as ET
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

    def check_assets(public, base_url):
        """Pages must only load scripts and styles from the site itself, and the
        built _headers must have its CSP filled in (see the `csp` recipe)."""
        asset = re.compile(r"<(?:script|link)\b[^>]*\b(?:src|href)=\"(https?://[^\"]+)\"[^>]*>")
        for page in public.rglob("*.html"):
            rel = page.relative_to(public)
            if rel.parts[0] == "projects" and len(rel.parts) > 2:
                continue
            for m in asset.finditer(page.read_text(encoding="utf-8")):
                tag, url = m.group(0), m.group(1)
                if tag.startswith("<link") and not re.search(r'rel="(stylesheet|preload|modulepreload)"', tag):
                    continue
                if not url.startswith(base_url):
                    error(f"{rel} loads {url} from another origin, which the CSP blocks")
        if "__CSP__" in (public / "_headers").read_text():
            error("_headers still has the CSP placeholder; build with `just build`")

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
        check_assets(public, base_url)
        if errors:
            sys.exit(f"{len(errors)} problem(s) found")
        print("Site checks passed")

    main("{{ public }}")

# Check internal links and anchors in the built site
links:
    just _check-links

# Check external links too (run weekly in CI)
links-external: build
    just _check-links external

# Shared by `links` and `links-external`: check links in the built site with
# lychee. Links to the site itself are checked against public/ rather than
# the live site. The project demos under /projects/<demo>/ are third-party
# builds and skipped.
_check-links mode="":
    #!/usr/bin/env -S uv run --script
    # /// script
    # requires-python = ">=3.11"
    # dependencies = []
    # ///
    import re, subprocess, sys
    from pathlib import Path

    mode = "{{ mode }}"
    base_url = re.search(r'^base_url = "(.*)"', Path("config.toml").read_text(), re.M).group(1)
    cwd = Path.cwd()
    args = [
        "lychee",
        "--no-progress",
        "--root-dir", str(cwd / "public"),
        "--remap", f"^{re.escape(base_url)}/(.*)$ file://{cwd}/public/$1",
        "--index-files", "index.html",
        "--include-fragments",
        "--exclude-path", "public/projects",
    ]
    if mode == "external":
        # LinkedIn rejects automated requests; 429s are rate limits, not broken links.
        args += ["--max-retries", "3", "--accept", "200..=299,429",
                  "--exclude", r"^https://(www\.)?linkedin\.com/"]
    else:
        args.append("--offline")
    args.append("public/**/*.html")
    sys.exit(subprocess.run(args).returncode)

# Fail if security.txt has expired
check-security-txt:
    #!/usr/bin/env bash
    set -euo pipefail
    expires=$(sed -n 's/^Expires: //p' static/.well-known/security.txt)
    if [[ $(date -u -d "$expires" +%s) -lt $(date -u +%s) ]]; then
        echo "::error file=static/.well-known/security.txt::Expired on $expires"
        exit 1
    fi
    echo "security.txt expires $expires"

# Spelling and grammar check; defaults to Markdown changed from the default branch
prose *files:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ $# -eq 0 ]]; then
        mapfile -t files < <(just prose-files)
        set -- "${files[@]}"
    fi
    if [[ $# -eq 0 ]]; then
        echo "No changed Markdown files"
        exit 0
    fi
    python3 .github/prose/harper.py --text "$@"

# Spelling and grammar check of every post
prose-all:
    #!/usr/bin/env bash
    set -euo pipefail
    mapfile -t files < <(git ls-files 'content/**.md')
    just prose "${files[@]}"

# Spelling and grammar findings as reviewdog rdjsonl (used by CI)
prose-json *files:
    python3 .github/prose/harper.py "$@"

# List Markdown added or changed since PROSE_BASE (default: the default branch)
prose-files:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -z ${PROSE_BASE:-} ]]; then
        default=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD || echo origin/master)
        PROSE_BASE=$(git merge-base HEAD "$default")
    fi
    git diff --name-only --diff-filter=AM "$PROSE_BASE" -- 'content/**.md'
    git ls-files --others --exclude-standard -- 'content/**.md'

# Audit the GitHub Actions workflows (online audits run when GH_TOKEN is set; pass --offline to skip)
zizmor *args:
    uvx zizmor@{{ zizmor_version }} --persona=pedantic "$@" .github

# Run Lighthouse against a local build; extra args go to lhci
lighthouse *args:
    #!/usr/bin/env bash
    set -euo pipefail
    port=8765
    out=$(mktemp -d)
    trap 'kill $server 2>/dev/null; rm -rf "$out"' EXIT
    zola build --base-url "http://localhost:$port" --output-dir "$out/site" --force
    just csp "$out/site"
    python3 -m http.server $port --directory "$out/site" > /dev/null 2>&1 &
    server=$!
    sleep 1
    just lighthouse-url "http://localhost:$port" "$@"

# Run Lighthouse with the CI thresholds against a deployed site, e.g. a preview URL
lighthouse-url url *args:
    #!/usr/bin/env bash
    set -euo pipefail
    url=${1%/}
    shift
    npx --yes @lhci/cli@{{ lhci_version }} autorun --config=.github/lighthouserc.json \
        --collect.url="$url/" \
        --collect.url="$url/post/" \
        --collect.url="$url/post/docker-on-fedora/" \
        --collect.url="$url/post/quaternions-in-md/" \
        "$@"

# Markdown table of the median scores from the last Lighthouse run
lighthouse-summary:
    #!/usr/bin/env python3
    import glob, json, statistics
    runs = {}
    for f in glob.glob(".lighthouseci/lhr-*.json"):
        r = json.load(open(f))
        runs.setdefault(r["finalDisplayedUrl"], []).append(
            {k: v["score"] for k, v in r["categories"].items()})
    cats = ["performance", "accessibility", "best-practices", "seo"]
    print("| Page | " + " | ".join(cats) + " |")
    print("|---|" + "---|" * len(cats))
    for url, rs in sorted(runs.items()):
        scores = [round(100 * statistics.median(r[c] for r in rs)) for c in cats]
        print(f"| {url} | " + " | ".join(map(str, scores)) + " |")

# Apply the monthly maintenance bumps (security.txt, footer year, Zola, KaTeX)
maintenance:
    #!/usr/bin/env -S uv run --script
    # /// script
    # requires-python = ">=3.11"
    # dependencies = []
    # ///
    # Routine version and date bumps, run monthly by
    # .github/workflows/maintenance.yml. Each step only edits files when
    # something is due, so a run with nothing to do leaves the tree clean
    # and no PR is opened.
    import base64, hashlib, json, os, re, urllib.request
    from datetime import datetime, timedelta, timezone
    from pathlib import Path

    today = datetime.now(timezone.utc).date()

    # security.txt: renew the expiry to a year out once it is within 90 days.
    sec = Path("static/.well-known/security.txt")
    text = sec.read_text()
    expires = datetime.strptime(re.search(r"^Expires: (\d{4}-\d{2}-\d{2})T", text, re.M).group(1), "%Y-%m-%d").date()
    if expires < today + timedelta(days=90):
        new = today + timedelta(days=365)
        sec.write_text(re.sub(r"^Expires: .*", f"Expires: {new}T00:00:00.000Z", text, flags=re.M))
        print(f"security.txt: Expires {expires} -> {new}")

    # Footer copyright end year.
    config = Path("config.toml")
    text = config.read_text()
    year = today.year
    if f'footer_copyright = "© 2017–{year}' not in text:
        config.write_text(re.sub(r'(footer_copyright = "© 2017–)\d{4}', rf"\g<1>{year}", text))
        print(f"footer: copyright year -> {year}")

    # Zola: track the latest release. ZOLA_LATEST can be set to skip the API call.
    justfile = Path("justfile")
    text = justfile.read_text()
    current = re.search(r'zola_version := "(.*)"', text).group(1)
    latest = os.environ.get("ZOLA_LATEST")
    if not latest:
        headers = {}
        if token := os.environ.get("GITHUB_TOKEN"):
            headers["Authorization"] = f"Bearer {token}"
        req = urllib.request.Request("https://api.github.com/repos/getzola/zola/releases/latest", headers=headers)
        with urllib.request.urlopen(req) as resp:
            latest = json.load(resp)["tag_name"].lstrip("v")

    def version_tuple(v):
        return tuple(int(p) for p in v.split("."))

    if latest and latest != current and version_tuple(latest) > version_tuple(current):
        justfile.write_text(re.sub(r'zola_version := ".*"', f'zola_version := "{latest}"', text))
        print(f"zola: {current} -> {latest}")

    # KaTeX: re-sync the self-hosted copy under static/katex with the version
    # serene's own templates pin, verifying each file against serene's own
    # jsdelivr SRI hash before trusting it.
    serene = Path("themes/serene/templates/post.html").read_text()
    ours_path = Path("templates/post.html")
    ours = ours_path.read_text()
    version = re.search(r"katex@([0-9.]+)/dist/katex\.min\.css", serene).group(1)
    changed = False
    for name in ("katex.min.css", "katex.min.js", "contrib/auto-render.min.js", "contrib/copy-tex.min.js"):
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

# Deploy the site to Cloudflare (CI does this on pushes to the default branch)
deploy: build
    {{ wrangler }} deploy

# Check the Cloudflare deploy config without deploying
deploy-dry-run: build
    {{ wrangler }} deploy --dry-run

# Upload a Cloudflare preview and print its URL; logs go to stderr
preview name message="":
    #!/usr/bin/env bash
    set -euo pipefail
    # The preview URL is only known once the preview exists, and Zola needs it
    # as the base URL. So upload once to get the URL, then rebuild and upload
    # again. Unchanged assets aren't re-uploaded, so the second pass is cheap.
    just build >&2
    url=$({{ wrangler }} preview --name "$1" --json | jq -r '.preview.urls[0]')
    [[ $url == https://* ]] || { echo "No preview URL returned" >&2; exit 1; }
    just build --base-url "$url" >&2
    {{ wrangler }} preview --name "$1" --message "$2" >&2
    echo "$url"

# Delete a Cloudflare preview
preview-delete name:
    {{ wrangler }} preview delete --worker-name {{ worker }} --name "$1" --skip-confirmation

# Serve the built site with Cloudflare's local runtime, including _headers and _redirects
preview-local: build
    {{ wrangler }} dev
