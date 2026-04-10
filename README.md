# Photo Album (Fotoalbum)

Een lokaal fotoalbum voor de Stadsmakerij. Bezoekers scannen een QR-code, uploaden foto's vanaf hun telefoon, en de foto's worden als diashow getoond op een beeldscherm. Alles draait lokaal op een Raspberry Pi — geen cloud, geen accounts.

- [Wat doet dit project?](#wat-doet-dit-project)
- [Installatie](#installatie)
- [De app starten](#de-app-starten)
- [Backup](#backup)
- [USB-sticks](#usb-sticks)
- [Mapstructuur](#mapstructuur)

## Wat doet dit project?

- **Uploaden**: Bezoekers uploaden foto's via een mobiele webpagina (bereikbaar via QR-code)
- **Galerij**: Overzicht van alle foto's als thumbnails
- **Diashow**: Fullscreen diashow voor op een beeldscherm, met QR-code overlay
- **Backup**: Automatische backup naar USB-sticks (elk uur)

## Installatie

Eén commando op de Raspberry Pi:

```bash
git clone https://github.com/stadsmakerij/photo-album.git ~/photo-album
cd ~/photo-album
./install.sh
```

Dit script regelt alles:
- Installeert systeem-pakketten (Python, git, rsync)
- Maakt een Python virtual environment aan met dependencies
- Maakt alle benodigde mappen aan
- Genereert en installeert een systemd-service (automatisch starten bij boot)
- Stelt de backup-cronjob in (elk uur)
- Toont het IP-adres en de URL na afloop

## De app starten

### Handmatig

```bash
cd ~/photo-album
venv/bin/python app.py
```

### Automatisch bij opstarten (aanbevolen)

Het install-script heeft de systemd-service al ingesteld. Beheer met:

```bash
sudo systemctl status photo-album   # Status bekijken
sudo systemctl restart photo-album  # Herstarten
sudo systemctl stop photo-album     # Stoppen
```

### Pagina's

| URL          | Functie                                |
|--------------|----------------------------------------|
| `/`          | Foto's uploaden (mobiel)               |
| `/gallery`   | Galerij met thumbnails                 |
| `/slideshow` | Fullscreen diashow voor scherm         |
| `/qr`        | QR-code bekijken en downloaden         |

## Backup

Het backup-script draait automatisch elk uur via cron en kopieert alle foto's naar aangesloten USB-sticks via rsync.

- Sticks die niet aangesloten zijn worden overgeslagen
- Resultaten worden gelogd in `logs/backup.log`
- Bij problemen (stick vol of niet aangesloten) verschijnt een melding op de diashow

Handmatig een backup starten:

```bash
./scripts/backup.sh
```

## USB-sticks

USB-sticks worden automatisch gedetecteerd. Gewoon insteken — het backup-script vindt ze vanzelf. Foto's worden opgeslagen in een `photo-album-backup/` map op elke stick.

Controleer of een stick herkend wordt:

```bash
lsblk
```

## Mapstructuur

```
photo-album/
├── app.py                 ← Flask-server
├── install.sh             ← Installatiescript (genereert systemd service)
├── templates/
│   ├── upload.html        ← Uploadpagina (mobiel)
│   ├── gallery.html       ← Galerij
│   ├── slideshow.html     ← Diashow
│   └── qr.html            ← QR-code pagina
├── static/
│   └── style.css
├── photos/
│   ├── originals/         ← Originele foto's (ongewijzigd)
│   ├── display/           ← Max 1920x1080 (diashow)
│   ├── thumbs/            ← Max 400x300 (galerij)
│   └── meta/              ← Metadata per foto (JSON)
├── scripts/
│   └── backup.sh          ← Backup naar USB-sticks
└── logs/
    └── backup.log
```
