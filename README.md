# Photo Album (Fotoalbum)

- [Wat doet dit project?](#wat-doet-dit-project)
- [Installatie](#installatie)
- [De app starten](#de-app-starten)
- [Backup](#backup)
- [USB-sticks instellen](#usb-sticks-instellen)
- [Mapstructuur](#mapstructuur)

Een lokaal fotoalbum voor de Stadsmakerij. Bezoekers scannen een QR-code, uploaden foto's vanaf hun telefoon, en de foto's worden als diashow getoond op een beeldscherm. Alles draait lokaal op een Raspberry Pi — geen cloud, geen accounts.

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

## USB-sticks instellen

1. Sluit USB-sticks aan op de Raspberry Pi

2. Maak mountpoints aan:

```bash
sudo mkdir -p /media/usb1 /media/usb2 /media/usb3 /media/usb4
```

3. Zoek de apparaatnamen op:

```bash
lsblk
```

4. Voeg de sticks toe aan `/etc/fstab` (de `nofail` optie zorgt dat de Pi opstart ook als een stick ontbreekt):

```
/dev/sda1 /media/usb1 vfat defaults,nofail 0 0
/dev/sdb1 /media/usb2 vfat defaults,nofail 0 0
/dev/sdc1 /media/usb3 vfat defaults,nofail 0 0
/dev/sdd1 /media/usb4 vfat defaults,nofail 0 0
```

5. Mount de sticks:

```bash
sudo mount -a
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
