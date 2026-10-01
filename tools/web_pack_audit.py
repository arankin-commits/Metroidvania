"""Audit Godot 4.7 PCKs and maintain the Web runtime-only resource selection.

Run from the project root: python tools/web_pack_audit.py --refresh-export
Then export Web and run: python tools/web_pack_audit.py --verify
"""
import argparse
import hashlib
import json
import re
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REVIEW = ROOT / "design/reviews"


def runtime_resources():
    classes = {}
    for directory in ["scripts", "addons"]:
        for path in (ROOT / directory).rglob("*.gd"):
            match = re.search(r"(?m)^class_name\s+(\w+)", path.read_text(encoding="utf-8-sig"))
            if match:
                classes[match[1]] = path.relative_to(ROOT).as_posix()
    config = (ROOT / "project.godot").read_text()
    main = re.search(r'run/main_scene="res://([^"]+)"', config).group(1)
    autoload = config.split("[autoload]", 1)[1].split("\n[", 1)[0]
    pending = [main, *[p.relative_to(ROOT).as_posix() for p in (ROOT / "scenes").glob("*.tscn")]]
    pending += re.findall(r'res://([^"]+)', autoload)
    seen = set()
    while pending:
        name = pending.pop()
        if name in seen:
            continue
        path = ROOT / name
        if not path.is_file():
            raise RuntimeError(f"Missing runtime dependency: {name}")
        seen.add(name)
        if path.suffix not in [".gd", ".tscn", ".tres", ".gdshader", ".shader"]:
            continue
        source = path.read_text(encoding="utf-8-sig")
        source = re.sub(r"(?m)^\s*#.*$", "", source)
        pending += re.findall(r'res://([^"\n\r\)\']+)', source)
        for relative in re.findall(r'(?:preload|load)\s*\(\s*"([^\"]+)"', source):
            if "://" in relative:
                continue
            resolved = (path.parent / relative).resolve()
            pending.append(resolved.relative_to(ROOT).as_posix())
        if path.suffix == ".gd":
            for symbol, class_path in classes.items():
                if re.search(r"\b" + re.escape(symbol) + r"\b", source):
                    pending.append(class_path)
    return sorted(seen)


def read_pack(path):
    sources = {}
    for imported in ROOT.rglob("*.import"):
        if any(part in ["Metroidvania-main", ".git"] for part in imported.parts):
            continue
        for mapped in re.findall(r'res://([^"\n]+)', imported.read_text(errors="replace")):
            if mapped.startswith(".godot/imported/"):
                sources[mapped] = imported.relative_to(ROOT).as_posix()[:-7]
    entries = []
    with path.open("rb") as stream:
        magic, version = struct.unpack("<II", stream.read(8))
        if magic != 0x43504447 or version != 4:
            raise RuntimeError("This inspector expects an unencrypted Godot PCK version4")
        stream.seek(20)
        flags, data_base, directory = struct.unpack("<IQQ", stream.read(20))
        if flags & 1:
            raise RuntimeError("Encrypted directory cannot be audited")
        stream.seek(directory)
        count = struct.unpack("<I", stream.read(4))[0]
        for _ in range(count):
            length = struct.unpack("<I", stream.read(4))[0]
            name = stream.read(length).rstrip(b"\0").decode()
            offset, size = struct.unpack("<QQ", stream.read(16))
            digest = stream.read(16).hex()
            file_flags = struct.unpack("<I", stream.read(4))[0]
            entries.append(dict(path=name, source=sources.get(name, name), offset=offset,
                                size=size, md5=digest, flags=file_flags))
        # Validate the table against actual media bytes, rather than trusting names.
        for entry in entries:
            if entry["path"].endswith((".ctex", ".sample", ".oggstr", ".mp3str")):
                absolute = entry["offset"] + (data_base if flags & 2 else 0)
                stream.seek(absolute)
                digest = hashlib.md5(stream.read(entry["size"])).hexdigest()
                if digest != entry["md5"]:
                    raise RuntimeError(f"Payload checksum mismatch: {entry['path']}")
    return dict(bytes=path.stat().st_size, directory=directory, count=count, entries=entries)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--refresh-export", action="store_true")
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    resources = runtime_resources()
    (REVIEW / "web-runtime-resources.json").write_text(json.dumps(resources, indent=2))
    if args.refresh_export:
        preset = ROOT / "export_presets.cfg"
        source = preset.read_text()
        line = "export_files=PackedStringArray(" + ", ".join(json.dumps("res://" + p) for p in resources) + ")"
        source = re.sub(r"(?m)^export_files=.*$", lambda _: line, source)
        source = source.replace('export_filter="all_resources"', 'export_filter="resources"')
        preset.write_text(source)
        print(f"Selected {len(resources)} runtime resources, including relative/global-class dependencies")
    pack = read_pack(ROOT / "docs/index.pck")
    (REVIEW / "index-pck-runtime-inventory.json").write_text(json.dumps(pack, indent=2))
    print(f"index.pck: {pack['bytes']:,} bytes, {pack['bytes']/1e6:.3f} MB, {pack['count']} entries")
    if args.verify:
        if pack["bytes"] >= 100_000_000:
            raise RuntimeError("Pack exceeds the stricter decimal100MB limit")
        before = json.loads((REVIEW / "index-pck-inventory.json").read_text())
        live = set(resources)
        current = {e["path"]: e for e in pack["entries"]}
        media_count = 0
        for old in before["entries"]:
            if old["source"] not in live or not old["path"].endswith((".ctex", ".sample", ".oggstr", ".mp3str")):
                continue
            if old["path"] not in current or old["md5"] != current[old["path"]]["md5"]:
                raise RuntimeError(f"Live media missing or changed: {old['source']}")
            media_count += 1
        for entry in pack["entries"]:
            if entry["path"].startswith(("design/", "tests/", "docs/")):
                raise RuntimeError("Development/export resource unexpectedly packed: " + entry["path"])
        print(f"PASS: below100MB; all {media_count} live media resources are byte-identical; no design/tests/docs resources")


if __name__ == "__main__":
    main()
