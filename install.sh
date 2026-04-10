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
echo "[1/6] Systeem-pakketten installeren..."
sudo apt-get update -qq
sudo apt-get install -y -qq python3 python3-venv python3-pip git rsync > /dev/null

# Clone or update repo
if [ -f "$APP_DIR/app.py" ]; then
    echo "[2/6] Repository al aanwezig, updaten..."
    git -C "$APP_DIR" pull --ff-only 2>/dev/null || true
else
    echo "[2/6] Repository clonen..."
    git clone "$REPO_URL" "$APP_DIR"
fi

# Python venv + dependencies
echo "[3/6] Python-omgeving opzetten..."
python3 -m venv "$APP_DIR/venv"
"$APP_DIR/venv/bin/pip" install --quiet --upgrade pip
"$APP_DIR/venv/bin/pip" install --quiet flask pillow qrcode

# Directory structure
echo "[4/6] Mappen aanmaken..."
mkdir -p "$APP_DIR/photos/originals"
mkdir -p "$APP_DIR/photos/display"
mkdir -p "$APP_DIR/photos/thumbs"
mkdir -p "$APP_DIR/photos/meta"
mkdir -p "$APP_DIR/logs"
chmod +x "$APP_DIR/scripts/backup.sh"

# Generate and install systemd service
echo "[5/6] Systemd-service instellen..."
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

# Cronjob for backup
echo "[6/6] Cronjob instellen..."
CRON_LINE="0 * * * * $APP_DIR/scripts/backup.sh"
(crontab -l 2>/dev/null | grep -v "photo-album/scripts/backup.sh"; echo "$CRON_LINE") | crontab -

# Detect network info
HOSTNAME=$(hostname)
IP=$(hostname -I 2>/dev/null | awk '{print $1}')

echo ""
echo "=== Installatie voltooid ==="
echo ""
echo "App starten:"
echo "  sudo systemctl start photo-album"
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
