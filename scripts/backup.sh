#!/bin/bash
# Backup photos to all mounted USB sticks in parallel
# Intended to run via cron every hour: 0 * * * * /path/to/photo-album/scripts/backup.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PHOTOS_DIR="$SCRIPT_DIR/../photos"
LOG_FILE="$SCRIPT_DIR/../logs/backup.log"
STATUS_FILE="$SCRIPT_DIR/../logs/backup_status.json"
MIN_FREE_MB=500
SD_MIN_FREE_MB=1024

mkdir -p "$(dirname "$LOG_FILE")"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
STICKS_FOUND=0
PIDS=()
WARNINGS=""
SD_WARNING=""

# Check free space on the Pi's own root filesystem (SD card)
SD_FREE_MB=$(df -m "$PHOTOS_DIR" | awk 'NR==2 {print $4}')
if [ -n "$SD_FREE_MB" ] && [ "$SD_FREE_MB" -lt "$SD_MIN_FREE_MB" ] 2>/dev/null; then
    SD_FREE_GB=$(awk "BEGIN {printf \"%.1f\", $SD_FREE_MB/1024}")
    SD_WARNING="SD-kaart bijna vol (${SD_FREE_GB}GB vrij)"
fi

# Auto-detect all mounted USB sticks
USB_MOUNTS=$(lsblk -o MOUNTPOINT,TRAN -nr 2>/dev/null | awk '$2 == "usb" && $1 != "" {print $1}')

for MOUNT in $USB_MOUNTS; do
    STICKS_FOUND=$((STICKS_FOUND + 1))
    DEST="$MOUNT/photo-album-backup/"
    rsync -a --delete "$PHOTOS_DIR/" "$DEST" &
    PIDS+=($!)

    # Check free space
    FREE_MB=$(df -m "$MOUNT" | awk 'NR==2 {print $4}')
    if [ "$FREE_MB" -lt "$MIN_FREE_MB" ] 2>/dev/null; then
        STICK_NAME=$(basename "$MOUNT")
        WARNINGS="${WARNINGS}${STICK_NAME} bijna vol (${FREE_MB}MB vrij). "
    fi
done

# Wait for all rsync processes to finish
FAILURES=0
for PID in "${PIDS[@]}"; do
    if ! wait "$PID"; then
        FAILURES=$((FAILURES + 1))
    fi
done

# Log results
if [ "$STICKS_FOUND" -eq 0 ]; then
    echo "$TIMESTAMP | Geen USB-sticks gevonden, backup overgeslagen" >> "$LOG_FILE"
elif [ "$FAILURES" -eq 0 ]; then
    echo "$TIMESTAMP | Backup voltooid naar $STICKS_FOUND stick(s)" >> "$LOG_FILE"
else
    SUCCEEDED=$((STICKS_FOUND - FAILURES))
    echo "$TIMESTAMP | Backup: $SUCCEEDED/$STICKS_FOUND stick(s) gelukt, $FAILURES mislukt" >> "$LOG_FILE"
fi

if [ -n "$SD_WARNING" ]; then
    echo "$TIMESTAMP | WAARSCHUWING: $SD_WARNING" >> "$LOG_FILE"
fi

if [ -n "$WARNINGS" ]; then
    echo "$TIMESTAMP | WAARSCHUWING: $WARNINGS" >> "$LOG_FILE"
fi

# Write status file for the web app. SD-kaart-vol heeft de hoogste prioriteit.
if [ -n "$SD_WARNING" ]; then
    STATUS="$SD_WARNING"
elif [ "$STICKS_FOUND" -eq 0 ]; then
    STATUS="Geen USB-sticks aangesloten — er wordt geen backup gemaakt"
elif [ "$FAILURES" -gt 0 ]; then
    SUCCEEDED=$((STICKS_FOUND - FAILURES))
    STATUS="Backup mislukt voor $FAILURES van $STICKS_FOUND stick(s)"
elif [ -n "$WARNINGS" ]; then
    STATUS="$WARNINGS"
else
    STATUS=""
fi

cat > "$STATUS_FILE" << ENDJSON
{"warning": "$STATUS", "timestamp": "$TIMESTAMP", "sticks": $STICKS_FOUND}
ENDJSON
