# Local commands for the site. Run `just` to list them.
# These wrap the same scripts and pinned versions CI uses.
#
# Needs zola (version in netlify.toml), plus for the checks: lychee, harper-cli,
# pipx (zizmor), and npx with Chrome (Lighthouse, Wrangler).

zizmor_version := "1.31.1"
lhci_version := "0.15.1"
wrangler_version := "4.151.1"

# List recipes
default:
    @just --list

# Build the site into public/
build:
    zola build

# Serve the site locally with live reload
serve:
    zola serve

# Run the same checks as the CI build, plus zizmor
check: build check-site links zizmor

# Check sitemap, feed and robots.txt in the built site
check-site:
    python3 scripts/check_site.py

# Check internal links and anchors in the built site
links:
    scripts/check_links.sh

# Check external links too (as the weekly workflow does)
links-external: build
    scripts/check_links.sh external

# Spelling and grammar check; defaults to Markdown changed from the default branch
prose *files:
    #!/usr/bin/env bash
    set -euo pipefail
    files=({{ files }})
    if [[ ${#files[@]} -eq 0 ]]; then
        default=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD || echo origin/master)
        base=$(git merge-base HEAD "$default")
        mapfile -t files < <(git diff --name-only --diff-filter=AM "$base" -- 'content/**.md'; git ls-files --others --exclude-standard -- 'content/**.md')
    fi
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "No changed Markdown files"
        exit 0
    fi
    python3 .github/prose/harper.py --text "${files[@]}"

# Spelling and grammar check of every post
prose-all:
    just prose $(git ls-files 'content/**.md')

# Audit the GitHub Actions workflows (online audits run when GH_TOKEN is set; pass --offline to skip)
zizmor *args:
    pipx run zizmor=={{ zizmor_version }} --persona=pedantic {{ args }} .github

# Run Lighthouse against a local build, with the CI thresholds; extra args go to lhci
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
    npx --yes @lhci/cli@{{ lhci_version }} autorun --config=.github/lighthouserc.json \
        --collect.url="http://localhost:$port/" \
        --collect.url="http://localhost:$port/post/" \
        --collect.url="http://localhost:$port/post/docker-on-fedora/" \
        --collect.url="http://localhost:$port/post/quaternions-in-md/" \
        {{ args }}

# Apply the monthly maintenance bumps (security.txt, footer year, Zola)
maintenance:
    scripts/maintenance.sh

# Check the Cloudflare deploy config without deploying
deploy-dry-run: build
    npx --yes wrangler@{{ wrangler_version }} deploy --dry-run

# Serve the built site with Cloudflare's local runtime, including _headers and _redirects
preview-local: build
    npx --yes wrangler@{{ wrangler_version }} dev
