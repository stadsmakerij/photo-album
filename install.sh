#!/bin/bash
# Install script for Photo Album on Raspberry Pi
set -e

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_URL="https://github.com/stadsmakerij/photo-album.git"
PORT=8080
CURRENT_USER=$(whoami)

echo "=== Photo Album installatie ==="
echo ""

# System dependencies
echo "[1/7] Systeem-pakketten installeren..."
sudo apt-get update -qq
sudo apt-get install -y -qq python3 python3-venv python3-pip git rsync udisks2 unclutter > /dev/null
sudo apt-get install -y -qq chromium-browser > /dev/null 2>&1 || sudo apt-get install -y -qq chromium > /dev/null

# Clone or update repo
if [ -f "$APP_DIR/app.py" ]; then
    echo "[2/7] Repository al aanwezig, updaten..."
    git -C "$APP_DIR" pull --ff-only 2>/dev/null || true
else
    echo "[2/7] Repository clonen..."
    git clone "$REPO_URL" "$APP_DIR"
fi

# Python venv + dependencies
echo "[3/7] Python-omgeving opzetten..."
python3 -m venv "$APP_DIR/venv"
"$APP_DIR/venv/bin/pip" install --quiet --upgrade pip
"$APP_DIR/venv/bin/pip" install --quiet flask pillow qrcode

# Directory structure
echo "[4/7] Mappen aanmaken..."
mkdir -p "$APP_DIR/photos/originals"
mkdir -p "$APP_DIR/photos/display"
mkdir -p "$APP_DIR/photos/thumbs"
mkdir -p "$APP_DIR/photos/meta"
mkdir -p "$APP_DIR/logs"
chmod +x "$APP_DIR/scripts/backup.sh"
chmod +x "$APP_DIR/scripts/kiosk.sh"

# Generate and install systemd service
echo "[5/7] Systemd-service instellen..."
cat > /tmp/photo-album.service << EOF
[Unit]
Description=Photo Album web server
After=network.target

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/python $APP_DIR/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo cp /tmp/photo-album.service /etc/systemd/system/photo-album.service
rm /tmp/photo-album.service
sudo systemctl daemon-reload
sudo systemctl enable photo-album
sudo systemctl restart photo-album

# Kiosk autostart (Chromium fullscreen slideshow on desktop login)
echo "[6/7] Kiosk-autostart instellen..."
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"
cat > "$AUTOSTART_DIR/photo-album-kiosk.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Photo Album Kiosk
Exec=$APP_DIR/scripts/kiosk.sh
X-GNOME-Autostart-enabled=true
EOF

# Disable screen blanking so the slideshow stays visible
sudo raspi-config nonint do_blanking 1 2>/dev/null || true

# Cronjob for backup
echo "[7/7] Cronjob instellen..."
CRON_LINE="0 * * * * $APP_DIR/scripts/backup.sh"
(crontab -l 2>/dev/null | grep -v "photo-album/scripts/backup.sh"; echo "$CRON_LINE") | crontab -

# Detect network info
HOSTNAME=$(hostname)
IP=$(hostname -I 2>/dev/null | awk '{print $1}')

echo ""
echo "=== Installatie voltooid ==="
echo ""
echo "App draait al via systemd."
echo ""
echo "Beheer:"
echo "  sudo systemctl status photo-album    # Status"
echo "  sudo systemctl restart photo-album   # Herstarten"
echo "  sudo systemctl stop photo-album      # Stoppen"
echo ""
echo "Bereikbaar op:"
if [ -n "$IP" ]; then
    echo "  http://$IP:$PORT"
fi
echo "  http://$HOSTNAME.local:$PORT"
echo ""
echo "QR-code downloaden:"
if [ -n "$IP" ]; then
    echo "  http://$IP:$PORT/qr"
fi
echo "  http://$HOSTNAME.local:$PORT/qr"
echo ""
echo "Backup cronjob is ingesteld (elk uur)."
echo "Sluit USB-sticks aan op /media/usb1 t/m /media/usb4 voor backup."
echo ""
echo "Kiosk-modus is ingesteld: na reboot start Chromium automatisch fullscreen."
echo "Reboot nu met: sudo reboot"
