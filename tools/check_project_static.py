from pathlib import Path
import configparser

root = Path(__file__).resolve().parents[1]
for required in ["project.godot", "export_presets.cfg", "scenes/Main.tscn", "scripts/Game.gd", ".github/workflows/build-android.yml", "assets/icon.png"]:
    path = root / required
    if not path.exists():
        raise SystemExit(f"Missing required file: {required}")

presets = (root / "export_presets.cfg").read_text(encoding="utf-8")
apk = presets.split("[preset.1]")[0]
aab = presets.split("[preset.1]")[1]
assert 'name="Android APK"' in apk
assert 'gradle_build/use_gradle_build=false' in apk
assert 'gradle_build/min_sdk' not in apk
assert 'gradle_build/target_sdk' not in apk
assert 'name="Android AAB"' in aab
assert 'gradle_build/use_gradle_build=true' in aab
assert 'gradle_build/export_format=1' in aab

scene = (root / "scenes/Main.tscn").read_text(encoding="utf-8")
assert 'path="res://scripts/Game.gd"' in scene

project = (root / "project.godot").read_text(encoding="utf-8")
assert 'run/main_scene="res://scenes/Main.tscn"' in project
assert 'config/icon="res://assets/icon.png"' in project

print("Static project checks passed.")
