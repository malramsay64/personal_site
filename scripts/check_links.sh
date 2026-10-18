#!/usr/bin/env bash
# Check links in the built site with lychee.
#   scripts/check_links.sh           internal links and #anchors only (offline)
#   scripts/check_links.sh external  external links too
# Links to the site itself are checked against public/ rather than the live site.
# The project demos under /projects/<demo>/ are third-party builds and skipped.
set -euo pipefail
cd "$(dirname "$0")/.."

base_url=$(sed -n 's/^base_url = "\(.*\)"/\1/p' config.toml)
args=(
    --no-progress
    --root-dir "$PWD/public"
    --remap "^${base_url//./\\.}/(.*)\$ file://$PWD/public/\$1"
    --index-files index.html
    --include-fragments
    --exclude-path public/projects
)
if [[ ${1:-} == external ]]; then
    # LinkedIn rejects automated requests; 429s are rate limits, not broken links.
    args+=(--max-retries 3 --accept '200..=299,429' --exclude '^https://(www\.)?linkedin\.com/')
else
    args+=(--offline)
fi
lychee "${args[@]}" 'public/**/*.html'
