import io
import json
import os
import glob
import uuid
from datetime import datetime

import qrcode
from flask import Flask, request, jsonify, render_template, send_from_directory, send_file
from PIL import Image
from werkzeug.utils import secure_filename

app = Flask(__name__)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PHOTOS_DIR = os.path.join(BASE_DIR, "photos")
ORIGINALS_DIR = os.path.join(PHOTOS_DIR, "originals")
DISPLAY_DIR = os.path.join(PHOTOS_DIR, "display")
THUMBS_DIR = os.path.join(PHOTOS_DIR, "thumbs")

DISPLAY_SIZE = (1920, 1080)
THUMB_SIZE = (400, 300)
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif", ".webp", ".heic"}

for d in [ORIGINALS_DIR, DISPLAY_DIR, THUMBS_DIR]:
    os.makedirs(d, exist_ok=True)


def allowed_file(filename):
    ext = os.path.splitext(filename)[1].lower()
    return ext in ALLOWED_EXTENSIONS


def generate_filename(original_filename, name=None):
    timestamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    unique = uuid.uuid4().hex[:6]
    if name:
        safe_name = secure_filename(name).replace(".", "_")
        return f"{timestamp}_{safe_name}_{unique}.jpg"
    base = os.path.splitext(secure_filename(original_filename))[0]
    return f"{timestamp}_{base}_{unique}.jpg"


def create_resized(source_path, dest_path, max_size):
    with Image.open(source_path) as img:
        img = img.convert("RGB")

        # Auto-rotate based on EXIF orientation
        try:
            from PIL import ExifTags
            exif = img.getexif()
            for tag, value in exif.items():
                if ExifTags.TAGS.get(tag) == "Orientation":
                    if value == 3:
                        img = img.rotate(180, expand=True)
                    elif value == 6:
                        img = img.rotate(270, expand=True)
                    elif value == 8:
                        img = img.rotate(90, expand=True)
                    break
        except (AttributeError, KeyError):
            pass

        img.thumbnail(max_size, Image.LANCZOS)
        img.save(dest_path, "JPEG", quality=85)


META_DIR = os.path.join(PHOTOS_DIR, "meta")
os.makedirs(META_DIR, exist_ok=True)


def save_meta(filename, caption="", shareable=False):
    meta_file = os.path.join(META_DIR, filename.replace(".jpg", ".json"))
    with open(meta_file, "w", encoding="utf-8") as f:
        json.dump({"caption": caption[:140], "shareable": shareable}, f)


def load_meta(filename):
    meta_file = os.path.join(META_DIR, filename.replace(".jpg", ".json"))
    if os.path.exists(meta_file):
        with open(meta_file, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"caption": "", "shareable": False}


def process_upload(file, name=None, caption="", shareable=False):
    filename = generate_filename(file.filename, name)
    original_path = os.path.join(ORIGINALS_DIR, filename)
    file.save(original_path)

    display_path = os.path.join(DISPLAY_DIR, filename)
    create_resized(original_path, display_path, DISPLAY_SIZE)

    thumb_path = os.path.join(THUMBS_DIR, filename)
    create_resized(original_path, thumb_path, THUMB_SIZE)

    save_meta(filename, caption, shareable)

    return filename


@app.route("/")
def index():
    return render_template("upload.html")


@app.route("/upload", methods=["POST"])
def upload():
    files = request.files.getlist("photos")
    name = request.form.get("name", "").strip()
    caption = request.form.get("caption", "").strip()
    shareable = request.form.get("shareable") == "1"

    if not files or all(f.filename == "" for f in files):
        return jsonify({"error": "Geen bestanden geselecteerd"}), 400

    uploaded = []
    errors = []

    for i, file in enumerate(files):
        if file.filename == "":
            continue
        if not allowed_file(file.filename):
            errors.append(f"{file.filename}: niet-ondersteund bestandstype")
            continue
        try:
            # Add index suffix to prevent filename collisions within a batch
            if len(files) > 1:
                timestamped_name = name if not name else f"{name}_{i + 1}"
            else:
                timestamped_name = name
            filename = process_upload(file, timestamped_name if timestamped_name else None, caption, shareable)
            uploaded.append(filename)
        except Exception as e:
            errors.append(f"{file.filename}: {str(e)}")

    return jsonify({"uploaded": uploaded, "errors": errors})


@app.route("/gallery")
def gallery():
    return render_template("gallery.html")


@app.route("/slideshow")
def slideshow():
    return render_template("slideshow.html")


@app.route("/photos")
def photos():
    files = glob.glob(os.path.join(DISPLAY_DIR, "*.jpg"))
    filenames = sorted(
        [os.path.basename(f) for f in files],
        reverse=True,
    )
    result = []
    for fn in filenames:
        meta = load_meta(fn)
        result.append({"filename": fn, "caption": meta["caption"], "shareable": meta["shareable"]})
    return jsonify(result)


@app.route("/photos/originals/<filename>")
def serve_original(filename):
    return send_from_directory(ORIGINALS_DIR, filename)


@app.route("/photos/display/<filename>")
def serve_display(filename):
    return send_from_directory(DISPLAY_DIR, filename)


@app.route("/photos/thumbs/<filename>")
def serve_thumb(filename):
    return send_from_directory(THUMBS_DIR, filename)


LOGS_DIR = os.path.join(BASE_DIR, "logs")
BACKUP_STATUS_FILE = os.path.join(LOGS_DIR, "backup_status.json")


@app.route("/status")
def status():
    if os.path.exists(BACKUP_STATUS_FILE):
        with open(BACKUP_STATUS_FILE, "r") as f:
            return jsonify(json.load(f))
    return jsonify({"warning": "", "timestamp": "", "sticks": 0})


@app.route("/qr")
def qr_page():
    return render_template("qr.html")


@app.route("/qr.png")
def qr_image():
    upload_url = request.url_root.rstrip("/")
    img = qrcode.make(upload_url, box_size=10, border=2)
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return send_file(buf, mimetype="image/png", download_name="stadsmakerij-qr.png")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
