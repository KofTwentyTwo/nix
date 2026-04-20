#!/usr/bin/env bash
# Script: confluence-blog.sh
# Purpose: Read and update Confluence blog posts via v1 REST API
# Usage:
#   ./confluence-blog.sh read <blog-id>
#   ./confluence-blog.sh update <blog-id> <body-file>
#
# MCP tools use v2 pages API which returns 404 for blog posts.
# This script uses v1 REST API which supports blog posts.

set -euo pipefail

BASE_URL="${CONFLUENCE_BASE_URL:?Set CONFLUENCE_BASE_URL}/rest/api/content"
EMAIL="${CONFLUENCE_EMAIL:?Set CONFLUENCE_EMAIL}"
TOKEN="${CONFLUENCE_API_TOKEN:?Set CONFLUENCE_API_TOKEN}"
AUTH_HEADER="Authorization: Basic $(echo -n "${EMAIL}:${TOKEN}" | base64)"

usage() {
    echo "Usage:"
    echo "  $0 read <blog-id>              # Print blog body (storage format) to stdout"
    echo "  $0 update <blog-id> <body-file> # Update blog with content from file"
    echo ""
    echo "Known blog IDs:"
    echo "  1312522252  GitOps blog"
    echo "  1311670308  Liquibase blog"
}

read_blog() {
    local blog_id="$1"
    curl -s -H "$AUTH_HEADER" \
        "${BASE_URL}/${blog_id}?expand=body.storage,version" \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)
print('TITLE:', data['title'])
print('VERSION:', data['version']['number'])
print('---BODY---')
print(data['body']['storage']['value'])
"
}

update_blog() {
    local blog_id="$1"
    local body_file="$2"

    if [[ ! -f "$body_file" ]]; then
        echo "Error: body file not found: $body_file" >&2
        exit 1
    fi

    # Fetch current metadata, build payload, and update -- all in one python3 call
    python3 - "$blog_id" "$body_file" "$BASE_URL" "$AUTH_HEADER" <<'PYEOF'
import json, sys, urllib.request

blog_id = sys.argv[1]
body_file = sys.argv[2]
base_url = sys.argv[3]
auth_header = sys.argv[4]

# Fetch current version and title
req = urllib.request.Request(
    f"{base_url}/{blog_id}?expand=version",
    headers={"Authorization": auth_header.replace("Authorization: ", "")}
)
with urllib.request.urlopen(req) as resp:
    meta = json.loads(resp.read())

title = meta["title"]
current_version = meta["version"]["number"]
new_version = current_version + 1

print(f"Updating: {title}")
print(f"Version: {current_version} -> {new_version}")

# Read body from file
with open(body_file, "r") as f:
    body = f.read()

# Build and send update
payload = json.dumps({
    "version": {"number": new_version},
    "title": title,
    "type": "blogpost",
    "body": {
        "storage": {
            "value": body,
            "representation": "storage"
        }
    }
}).encode("utf-8")

req = urllib.request.Request(
    f"{base_url}/{blog_id}",
    data=payload,
    method="PUT",
    headers={
        "Authorization": auth_header.replace("Authorization: ", ""),
        "Content-Type": "application/json"
    }
)

try:
    with urllib.request.urlopen(req) as resp:
        result = json.loads(resp.read())
        print(f"Updated to version {result['version']['number']}")
except urllib.error.HTTPError as e:
    error_body = e.read().decode("utf-8")
    print(f"Error {e.code}: {error_body}", file=sys.stderr)
    sys.exit(1)
PYEOF
}

case "${1:-}" in
    read)
        [[ -z "${2:-}" ]] && { echo "Error: blog ID required"; usage; exit 1; }
        read_blog "$2"
        ;;
    update)
        [[ -z "${2:-}" ]] && { echo "Error: blog ID required"; usage; exit 1; }
        [[ -z "${3:-}" ]] && { echo "Error: body file required"; usage; exit 1; }
        update_blog "$2" "$3"
        ;;
    *)
        usage
        exit 1
        ;;
esac
