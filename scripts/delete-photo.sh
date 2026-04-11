#!/bin/bash
# Delete a single photo and all its variants (original, display, thumb, meta).
# Usage: ./scripts/delete-photo.sh <filename>
# Example: ./scripts/delete-photo.sh 2026-04-11_133022_rick_abc123.jpg
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <filename>"
    echo "Example: $0 2026-04-11_133022_rick_abc123.jpg"
    exit 1
fi

PHOTO="$1"
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
META_NAME="${PHOTO%.jpg}.json"

FILES=(
    "$APP_DIR/photos/originals/$PHOTO"
    "$APP_DIR/photos/display/$PHOTO"
    "$APP_DIR/photos/thumbs/$PHOTO"
    "$APP_DIR/photos/meta/$META_NAME"
)

removed=0
for f in "${FILES[@]}"; do
    if [ -f "$f" ]; then
        rm -f "$f"
        echo "Removed: $f"
        removed=$((removed + 1))
    fi
done

if [ "$removed" -eq 0 ]; then
    echo "No files found for: $PHOTO"
    exit 1
fi

echo "Done. $removed file(s) removed."
