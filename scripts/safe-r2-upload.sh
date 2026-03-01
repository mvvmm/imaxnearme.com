#!/usr/bin/env bash
#
# Uploads a file to R2, but refuses if the new file is 10%+ smaller than the existing one.
#
# Usage: ./safe-r2-upload.sh <bucket/key> <local-file>

set -euo pipefail

OBJECT_PATH="$1"
LOCAL_FILE="$2"

LOCAL_SIZE=$(wc -c < "$LOCAL_FILE" | tr -d ' ')

# Get remote object size via wrangler (download to temp file)
TEMP=$(mktemp)
trap 'rm -f "$TEMP"' EXIT

if wrangler r2 object get "$OBJECT_PATH" --file="$TEMP" --remote 2>/dev/null; then
  REMOTE_SIZE=$(wc -c < "$TEMP" | tr -d ' ')
  THRESHOLD=$(( REMOTE_SIZE * 90 / 100 ))

  if [ "$LOCAL_SIZE" -lt "$THRESHOLD" ]; then
    echo "ABORTED: Local file ($LOCAL_SIZE bytes) is more than 10% smaller than remote ($REMOTE_SIZE bytes)." >&2
    echo "This likely indicates data loss. Use wrangler directly to force upload." >&2
    exit 1
  fi

  echo "Size check passed: local=$LOCAL_SIZE remote=$REMOTE_SIZE"
else
  echo "No existing remote object, uploading fresh."
fi

wrangler r2 object put "$OBJECT_PATH" --file="$LOCAL_FILE" --remote
