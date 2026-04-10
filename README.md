# Photo Album (Fotoalbum)

- [Wat doet dit project?](#wat-doet-dit-project)
- [Vereisten](#vereisten)
- [Installatie](#installatie)
- [De app starten](#de-app-starten)
- [Backup instellen](#backup-instellen)
- [Mapstructuur](#mapstructuur)

Een lokaal fotoalbum voor de Stadsmakerij. Bezoekers scannen een QR-code, uploaden foto's vanaf hun telefoon, en de foto's worden als diashow getoond op een beeldscherm. Alles draait lokaal op een Raspberry Pi — geen cloud, geen accounts.

## Wat doet dit project?

- **Uploaden**: Bezoekers uploaden foto's via een mobiele webpagina (bereikbaar via QR-code)
- **Galerij**: Overzicht van alle foto's als thumbnails
- **Diashow**: Fullscreen diashow voor op een beeldscherm
- **Backup**: Automatische nachtelijke backup naar USB-sticks

## Vereisten

- Raspberry Pi OS (Debian-based) of een ander Linux-systeem
- Python 3.9 of hoger
- pip

## Installatie

```bash
# Clone de repository
git clone <repo-url> /home/pi/photo-album
cd /home/pi/photo-album

# Installeer Python-pakketten
pip install flask pillow

# Maak het backup-script uitvoerbaar
chmod +x scripts/backup.sh
```

## De app starten

```bash
# Start de server (bereikbaar op poort 5000)
python app.py
```

De app is nu bereikbaar op `http://<ip-adres-van-pi>:5000`.

### Pagina's

| URL          | Functie                          |
|--------------|----------------------------------|
| `/`          | Foto's uploaden (mobiel)         |
| `/gallery`   | Galerij met thumbnails           |
| `/slideshow` | Fullscreen diashow voor scherm   |

### QR-code

Maak een QR-code die verwijst naar `http://<ip-adres-van-pi>:5000` en hang deze op in de Stadsmakerij. Bezoekers scannen de code en kunnen direct foto's uploaden.

## Backup instellen

Het backup-script kopieert alle foto's naar USB-sticks via rsync.

### USB-sticks labelen en mounten

1. Sluit maximaal 4 USB-sticks aan op de Raspberry Pi
2. Maak mountpoints aan:

```bash
sudo mkdir -p /media/usb1 /media/usb2 /media/usb3 /media/usb4
```

3. Zoek de apparaatnamen op:

```bash
lsblk
```

4. Voeg de sticks toe aan `/etc/fstab` met de `nofail` optie (zodat de Pi gewoon opstart als een stick ontbreekt):

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

### Cronjob instellen

Het backup-script draait elk uur. Stel de cronjob in:

```bash
crontab -e
```

Voeg de volgende regel toe:

```
0 * * * * /home/pi/photo-album/scripts/backup.sh
```

### Handmatig een backup maken

```bash
./scripts/backup.sh
```

Resultaten worden gelogd in `logs/backup.log`.

## Mapstructuur

```
photo-album/
├── app.py                 ← Flask-server
├── templates/
│   ├── upload.html        ← Uploadpagina (mobiel)
│   ├── gallery.html       ← Galerij
│   └── slideshow.html     ← Diashow
├── static/
│   └── style.css
├── photos/
│   ├── originals/         ← Originele foto's (ongewijzigd)
│   ├── display/           ← Max 1920x1080 (diashow)
│   └── thumbs/            ← Max 400x300 (galerij)
├── scripts/
│   └── backup.sh          ← Backup naar USB-sticks
├── logs/
│   └── backup.log
└── README.md
```
