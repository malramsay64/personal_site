# Commands for building and checking the site. Run `just` to list them.
# CI runs these same recipes, so local runs and CI can't drift apart.
#
# Needs zola (version in netlify.toml), plus for the checks: lychee, harper-cli,
# pipx (zizmor), jq, and npx with Chrome (Lighthouse, Wrangler).

set positional-arguments

zizmor_version := "1.31.1"
lhci_version := "0.15.1"
wrangler_version := "4.151.1"
wrangler := "npx --yes wrangler@" + wrangler_version
worker := "malramsay-com"

# List recipes
default:
    @just --list

# Build the site into public/
build:
    zola build

# Serve the site locally with live reload
serve:
    zola serve

# Checks run by the CI build on every push
ci: build check-site links check-security-txt

# Everything in `ci`, plus zizmor
check: ci zizmor

# Check sitemap, feed and robots.txt in the built site
check-site:
    python3 scripts/check_site.py

# Check internal links and anchors in the built site
links:
    scripts/check_links.sh

# Check external links too (run weekly in CI)
links-external: build
    scripts/check_links.sh external

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
    pipx run zizmor=={{ zizmor_version }} --persona=pedantic "$@" .github

# Run Lighthouse against a local build; extra args go to lhci
lighthouse *args:
    #!/usr/bin/env bash
    set -euo pipefail
    port=8765
    out=$(mktemp -d)
    trap 'kill $server 2>/dev/null; rm -rf "$out"' EXIT
    zola build --base-url "http://localhost:$port" --output-dir "$out/site" --force
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

# Apply the monthly maintenance bumps (security.txt, footer year, Zola)
maintenance:
    scripts/maintenance.sh

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
    zola build >&2
    url=$({{ wrangler }} preview --name "$1" --json | jq -r '.preview.urls[0]')
    [[ $url == https://* ]] || { echo "No preview URL returned" >&2; exit 1; }
    zola build --base-url "$url" >&2
    {{ wrangler }} preview --name "$1" --message "$2" >&2
    echo "$url"

# Delete a Cloudflare preview
preview-delete name:
    {{ wrangler }} preview delete --worker-name {{ worker }} --name "$1" --skip-confirmation

# Serve the built site with Cloudflare's local runtime, including _headers and _redirects
preview-local: build
    {{ wrangler }} dev
