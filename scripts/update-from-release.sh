#!/usr/bin/env bash
# update-from-release.sh
#
# Fetches the latest upstream Archon release from GitHub, downloads the
# AppImage asset, computes its sha256, and rewrites PKGBUILD with the new
# pkgver and sha256sums values.
#
# Usage:
#   ./scripts/update-from-release.sh [RELEASE_API_URL]
#
# Arguments:
#   RELEASE_API_URL  Optional. GitHub API URL for the release to target.
#                    Defaults to the latest release of RPGLogs/Uploaders-archon.
#
# Environment:
#   No required environment variables. A GitHub token can be passed via the
#   standard GITHUB_TOKEN variable to avoid rate limiting on the API call.
#
# Exit codes:
#   0  PKGBUILD was updated (or already current)
#   1  A required value could not be determined (tag, asset URL, etc.)

set -euo pipefail

REPO_API_URL="${1:-https://api.github.com/repos/RPGLogs/Uploaders-archon/releases/latest}"

# fetch_release_json
#
# Calls the GitHub releases API and prints the raw JSON response to stdout.
# Passes an Authorization header when GITHUB_TOKEN is set so authenticated
# callers get a higher rate limit.
fetch_release_json() {
  local url="$1"
  local curl_args=(-fsSL)

  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  curl "${curl_args[@]}" "${url}"
}

# parse_version
#
# Extracts the semver string from a GitHub tag name (strips the leading "v").
# Prints the version to stdout, e.g. "9.0.1".
# Exits 1 if the tag is missing or null.
parse_version() {
  local release_json="$1"
  local tag version

  tag="$(jq -r '.tag_name' <<<"${release_json}")"

  if [[ -z "${tag}" || "${tag}" == "null" ]]; then
    echo "Failed to determine upstream release tag" >&2
    exit 1
  fi

  version="${tag#v}"
  echo "${version}"
}

# parse_asset_url
#
# Finds the browser download URL for the first .AppImage asset in the release.
# Prints the URL to stdout.
# Exits 1 if no AppImage asset is found.
parse_asset_url() {
  local release_json="$1"
  local asset_url

  asset_url="$(
    jq -r '
      .assets[]
      | select(.name | endswith(".AppImage"))
      | .browser_download_url
    ' <<<"${release_json}" | head -n1
  )"

  if [[ -z "${asset_url}" ]]; then
    echo "Failed to find AppImage asset in upstream release" >&2
    exit 1
  fi

  echo "${asset_url}"
}

# compute_sha256
#
# Downloads the asset at the given URL to a temp file, computes its sha256,
# and prints the hex digest to stdout.
# The temp file is cleaned up automatically via a trap.
compute_sha256() {
  local asset_url="$1"
  local tmpfile

  tmpfile="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '${tmpfile}'" EXIT

  curl -fsSL -o "${tmpfile}" "${asset_url}"
  sha256sum "${tmpfile}" | awk '{print $1}'
}

# update_pkgbuild
#
# Rewrites pkgver and sha256sums in PKGBUILD in-place.
update_pkgbuild() {
  local version="$1"
  local sha256="$2"

  sed -i -E "s/^pkgver=.*/pkgver=${version}/" PKGBUILD
  sed -i -E "/^sha256sums=\(/,/^\)/ s/'[0-9a-f]{64}'/'${sha256}'/" PKGBUILD
}

# main
#
# Orchestrates the full update flow:
#   1. Fetch the latest release JSON from GitHub
#   2. Parse the version and AppImage asset URL
#   3. Skip early if PKGBUILD is already at the latest version
#   4. Download the asset and compute its sha256
#   5. Rewrite PKGBUILD with the new version and checksum
main() {
  local release_json version asset_url sha256
  local current_ver

  echo "Fetching release info from ${REPO_API_URL} ..."
  release_json="$(fetch_release_json "${REPO_API_URL}")"

  version="$(parse_version "${release_json}")"
  asset_url="$(parse_asset_url "${release_json}")"

  # Skip the download entirely when PKGBUILD is already up to date.
  current_ver="$(sed -n 's/^pkgver=//p' PKGBUILD)"
  if [[ "${version}" == "${current_ver}" ]]; then
    printf 'PKGBUILD is already at %s, nothing to do.\n' "${version}"
    exit 0
  fi

  printf 'Upstream version: %s (current: %s)\n' "${version}" "${current_ver}"
  printf 'Downloading asset to compute sha256: %s\n' "${asset_url}"

  sha256="$(compute_sha256 "${asset_url}")"

  update_pkgbuild "${version}" "${sha256}"

  printf 'Updated PKGBUILD to v%s (%s)\n' "${version}" "${sha256}"
}

main
