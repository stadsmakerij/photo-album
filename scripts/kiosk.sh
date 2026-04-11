#!/bin/bash
# Start Chromium in kiosk mode showing the slideshow.
# Restarts automatically if Chromium crashes or is closed.

# Singleton: exit if another instance of this script is already running.
# Prevents two wrappers (labwc autostart + systemd-xdg-autostart) from
# fighting over Chromium's profile lock and causing a restart loop.
LOCK_FILE=/tmp/photo-album-kiosk.lock
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

URL="http://localhost:8080/slideshow"

if command -v chromium-browser >/dev/null 2>&1; then
    BROWSER=chromium-browser
else
    BROWSER=chromium
fi

command -v unclutter >/dev/null 2>&1 && unclutter -idle 1 -root &

# Wait for the Flask server to be reachable before opening Chromium
for _ in $(seq 1 60); do
    if curl -s -o /dev/null --max-time 1 "$URL"; then
        break
    fi
    sleep 1
done

while true; do
    "$BROWSER" \
        --kiosk \
        --noerrdialogs \
        --disable-infobars \
        --disable-session-crashed-bubble \
        --disable-features=Translate,TranslateUI \
        --check-for-update-interval=31536000 \
        --password-store=basic \
        --no-first-run \
        --lang=nl-NL \
        --accept-lang=nl-NL,nl \
        --disable-gpu \
        --disable-extensions \
        --disable-sync \
        --disable-background-networking \
        --process-per-site \
        "$URL"
    sleep 2
done
