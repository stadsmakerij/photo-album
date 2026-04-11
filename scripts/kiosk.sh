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
PROFILE_DIR="$HOME/.config/photo-album-kiosk"

if command -v chromium-browser >/dev/null 2>&1; then
    BROWSER=chromium-browser
else
    BROWSER=chromium
fi

# Pre-seed the Chromium profile so translate is permanently disabled.
# Flags alone are sometimes ignored once the profile has stored a preference.
mkdir -p "$PROFILE_DIR/Default"
cat > "$PROFILE_DIR/Default/Preferences" << 'EOF'
{
  "translate": {"enabled": false},
  "translate_blocked_languages": ["nl", "en"],
  "translate_site_blacklist": ["localhost"],
  "intl": {"accept_languages": "nl-NL,nl", "selected_languages": "nl-NL,nl"},
  "credentials_enable_service": false,
  "profile": {"password_manager_enabled": false}
}
EOF

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
        --user-data-dir="$PROFILE_DIR" \
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
