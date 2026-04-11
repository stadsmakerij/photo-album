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

while true; do
    "$BROWSER" \
        --kiosk \
        --noerrdialogs \
        --disable-infobars \
        --disable-session-crashed-bubble \
        --disable-features=TranslateUI \
        --check-for-update-interval=31536000 \
        "$URL"
    sleep 2
done
