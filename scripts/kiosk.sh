#!/bin/bash
# Start Chromium in kiosk mode showing the slideshow.
# Restarts automatically if Chromium crashes or is closed.

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
        --single-process \
        --disable-gpu \
        --disable-extensions \
        --disable-sync \
        --disable-background-networking \
        --js-flags=--max-old-space-size=128 \
        "$URL"
    sleep 2
done
