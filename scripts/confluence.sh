#!/usr/bin/env bash
# Script: confluence.sh
# Purpose: Read, update, and fix layout for Confluence pages and blog posts
# Usage:
#   confluence.sh read <id>                # Print content (storage format) to stdout
#   confluence.sh update <id> <body-file>  # Update content from file, auto-fix full-width
#   confluence.sh fix-layout <id>          # Fix full-width layout without changing content
#
# Auto-detects content type (page vs blogpost) from the API response.
# All updates automatically fix full-width layout (tables, code blocks, properties).
#
# Requires CONFLUENCE_API_TOKEN env var.

set -euo pipefail

BASE_URL="${CONFLUENCE_BASE_URL:?Set CONFLUENCE_BASE_URL (e.g. https://yoursite.atlassian.net/wiki)}"
V1_API="${BASE_URL}/rest/api/content"
EMAIL="${CONFLUENCE_EMAIL:?Set CONFLUENCE_EMAIL}"

if [[ -z "${CONFLUENCE_API_TOKEN:-}" ]]; then
    echo "Error: CONFLUENCE_API_TOKEN env var is not set" >&2
    exit 1
fi

usage() {
    cat <<EOF
Usage:
  $0 read <id>                 Read content (storage format) to stdout
  $0 update <id> <body-file>   Update content from file, auto-fix full-width
  $0 fix-layout <id>           Fix full-width layout without changing body

Auto-detects content type (page vs blogpost).
All updates fix: table layouts, code block layouts, appearance properties.

Requires CONFLUENCE_API_TOKEN env var.
EOF
}

# All API logic in python3 for reliable JSON handling and URL encoding
run_python() {
    python3 - "$@" <<'PYEOF'
import json, sys, urllib.request, urllib.error, base64, re

# ── Config ──────────────────────────────────────────────────────────────────
EMAIL = __import__("os").environ["CONFLUENCE_EMAIL"]
TOKEN = __import__("os").environ["CONFLUENCE_API_TOKEN"]
BASE = __import__("os").environ["CONFLUENCE_BASE_URL"]
V1 = f"{BASE}/rest/api/content"
AUTH = "Basic " + base64.b64encode(f"{EMAIL}:{TOKEN}".encode()).decode()
HEADERS = {"Authorization": AUTH, "Content-Type": "application/json"}

def api_get(url):
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())

def api_put(url, payload):
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="PUT", headers=HEADERS)
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())

def api_post(url, payload):
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="POST", headers=HEADERS)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        if e.code == 409:
            # Property already exists; update it with PUT instead
            return None
        raise

def api_put_property(url, payload):
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="PUT", headers=HEADERS)
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


# ── Full-width layout fixes ────────────────────────────────────────────────
def fix_storage_layout(html):
    """Fix data-layout='default' to 'full-width' on tables and code macros."""
    # Fix tables
    html = html.replace('data-layout="default"', 'data-layout="full-width"')
    # Add data-layout to code macros that lack it
    html = re.sub(
        r'(<ac:structured-macro\s+ac:name="code")(?![^>]*data-layout)',
        r'\1 data-layout="full-width"',
        html
    )
    return html

def set_appearance_properties(content_id):
    """Set full-width appearance properties via v1 REST API."""
    props_url = f"{V1}/{content_id}/property"
    for key in ["content-appearance-published", "content-appearance-draft"]:
        payload = {"key": key, "value": "full-width"}
        result = api_post(props_url, payload)
        if result is None:
            # Property exists; fetch current version and PUT update
            try:
                current = api_get(f"{props_url}/{key}")
                ver = current["version"]["number"]
                update_payload = {
                    "key": key,
                    "value": "full-width",
                    "version": {"number": ver + 1}
                }
                api_put_property(f"{props_url}/{key}", update_payload)
            except urllib.error.HTTPError:
                pass  # Best effort
    print("  Layout properties set to full-width", file=sys.stderr)


# ── Commands ────────────────────────────────────────────────────────────────
def cmd_read(content_id):
    data = api_get(f"{V1}/{content_id}?expand=body.storage,version")
    ctype = data.get("type", "unknown")
    print(f"TYPE: {ctype}")
    print(f"TITLE: {data['title']}")
    print(f"VERSION: {data['version']['number']}")
    print("---BODY---")
    print(data["body"]["storage"]["value"])

def cmd_update(content_id, body_file):
    # Fetch current metadata
    meta = api_get(f"{V1}/{content_id}?expand=body.storage,version")
    title = meta["title"]
    ctype = meta["type"]  # "page" or "blogpost"
    current_version = meta["version"]["number"]
    new_version = current_version + 1

    # Read body from file
    with open(body_file, "r") as f:
        body = f.read()

    # Fix full-width layout in storage format
    body = fix_storage_layout(body)

    print(f"Updating ({ctype}): {title}")
    print(f"Version: {current_version} -> {new_version}")

    # Build and send update
    payload = {
        "version": {"number": new_version},
        "title": title,
        "type": ctype,
        "body": {
            "storage": {
                "value": body,
                "representation": "storage"
            }
        }
    }

    try:
        result = api_put(f"{V1}/{content_id}", payload)
        print(f"Updated to version {result['version']['number']}")
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8")
        print(f"Error {e.code}: {error_body}", file=sys.stderr)
        sys.exit(1)

    # Set full-width appearance properties
    set_appearance_properties(content_id)

def cmd_fix_layout(content_id):
    # Fetch current content
    data = api_get(f"{V1}/{content_id}?expand=body.storage,version")
    title = data["title"]
    ctype = data["type"]
    current_version = data["version"]["number"]
    body = data["body"]["storage"]["value"]

    # Fix layout in storage format
    fixed_body = fix_storage_layout(body)

    if fixed_body == body:
        print(f"No layout fixes needed for: {title}")
    else:
        new_version = current_version + 1
        print(f"Fixing layout ({ctype}): {title}")
        print(f"Version: {current_version} -> {new_version}")

        payload = {
            "version": {"number": new_version, "message": "Fix full-width layout"},
            "title": title,
            "type": ctype,
            "body": {
                "storage": {
                    "value": fixed_body,
                    "representation": "storage"
                }
            }
        }

        try:
            result = api_put(f"{V1}/{content_id}", payload)
            print(f"Updated to version {result['version']['number']}")
        except urllib.error.HTTPError as e:
            error_body = e.read().decode("utf-8")
            print(f"Error {e.code}: {error_body}", file=sys.stderr)
            sys.exit(1)

    # Always set appearance properties
    set_appearance_properties(content_id)


# ── Main ────────────────────────────────────────────────────────────────────
if len(sys.argv) < 3:
    print("Error: command and content ID required", file=sys.stderr)
    sys.exit(1)

command = sys.argv[1]
content_id = sys.argv[2]

if command == "read":
    cmd_read(content_id)
elif command == "update":
    if len(sys.argv) < 4:
        print("Error: body file required for update", file=sys.stderr)
        sys.exit(1)
    cmd_update(content_id, sys.argv[3])
elif command == "fix-layout":
    cmd_fix_layout(content_id)
else:
    print(f"Unknown command: {command}", file=sys.stderr)
    sys.exit(1)
PYEOF
}

case "${1:-}" in
    read)
        [[ -z "${2:-}" ]] && { echo "Error: content ID required" >&2; usage; exit 1; }
        run_python read "$2"
        ;;
    update)
        [[ -z "${2:-}" ]] && { echo "Error: content ID required" >&2; usage; exit 1; }
        [[ -z "${3:-}" ]] && { echo "Error: body file required" >&2; usage; exit 1; }
        [[ ! -f "$3" ]] && { echo "Error: body file not found: $3" >&2; exit 1; }
        run_python update "$2" "$3"
        ;;
    fix-layout)
        [[ -z "${2:-}" ]] && { echo "Error: content ID required" >&2; usage; exit 1; }
        run_python fix-layout "$2"
        ;;
    *)
        usage
        exit 1
        ;;
esac
