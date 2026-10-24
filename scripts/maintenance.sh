#!/usr/bin/env bash
# Routine version and date bumps, run monthly by .github/workflows/maintenance.yml.
# Each step only edits files when something is due, so a run with nothing to do
# leaves the tree clean and no PR is opened.
set -euo pipefail
cd "$(dirname "$0")/.."

today=$(date -u +%Y-%m-%d)
year=$(date -u +%Y)

# security.txt: renew the expiry to a year out once it is within 90 days.
sec=static/.well-known/security.txt
expires=$(sed -n 's/^Expires: \([0-9-]*\)T.*/\1/p' "$sec")
if [[ $(date -u -d "$expires" +%s) -lt $(date -u -d "$today + 90 days" +%s) ]]; then
    new=$(date -u -d "$today + 1 year" +%Y-%m-%dT00:00:00.000Z)
    sed -i "s/^Expires: .*/Expires: $new/" "$sec"
    echo "security.txt: Expires $expires -> $new"
fi

# Footer copyright end year.
if ! grep -q "^footer_copyright = \"© 2017–$year" config.toml; then
    sed -i -E "s/^(footer_copyright = \"© 2017–)[0-9]{4}/\1$year/" config.toml
    echo "footer: copyright year -> $year"
fi

# Zola: track the latest release. ZOLA_LATEST can be set to skip the API call.
latest=${ZOLA_LATEST:-$(curl -fsSL \
    ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
    https://api.github.com/repos/getzola/zola/releases/latest \
    | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p')}
current=$(sed -n 's/^zola_version := "\(.*\)"/\1/p' justfile)
if [[ -n $latest && $latest != "$current" ]] \
    && [[ $(printf '%s\n%s\n' "$current" "$latest" | sort -V | tail -1) == "$latest" ]]; then
    sed -i "s/^zola_version := \".*\"/zola_version := \"$latest\"/" justfile
    echo "zola: $current -> $latest"
fi
