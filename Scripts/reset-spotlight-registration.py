#!/usr/bin/env python3
"""Unregister duplicate DevKit builds while keeping one installed app.

This only removes matching Launch Services records. It never resets the system
Spotlight database, deletes app files, or edits the user's Quick Key assignments.
"""
import argparse
import json
from pathlib import Path
import re
import subprocess

REGISTRY = '/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'
ROOT = Path(__file__).resolve().parents[1]
BUNDLE_IDS = {'app.devkit.macos', 'app.devkit.preview', 'app.devkit.layout-check', 'app.devkit.ui-review'}


def registrations(dump):
    for block in dump.split('bundle id:'):
        identifier = re.search(r'^identifier:\s+([^\n]+)$', block, re.M)
        location = re.search(r'^path:\s+(.+?)\s+\(0x[0-9a-f]+\)\s*$', block, re.M)
        if identifier and location and identifier.group(1).strip() in BUNDLE_IDS:
            yield identifier.group(1).strip(), Path(location.group(1))


def in_scope(app, root=ROOT, home=Path.home()):
    if app in {Path('/Applications/DevKit.app'), home / 'Applications/DevKit.app', home / '.Trash/DevKit.app'}:
        return True
    if app.is_relative_to(root):
        return True
    derived = home / 'Library/Developer/Xcode/DerivedData'
    if app.is_relative_to(derived):
        parts = app.relative_to(derived).parts
        return len(parts) > 1 and parts[0].startswith('DevKit-')
    return False


def main():
    default_keep = Path('/Applications/DevKit.app')
    if not default_keep.exists():
        default_keep = Path.home() / 'Applications/DevKit.app'
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--keep', type=Path, default=default_keep, help='Installed app to keep registered')
    parser.add_argument('--include-installed', action='store_true', help='Also unregister installed DevKit copies')
    parser.add_argument('--dry-run', action='store_true', help='List matching records without unregistering them')
    args = parser.parse_args()
    keep = None if args.include_installed else args.keep.absolute()
    dump = subprocess.check_output([REGISTRY, '-dump'], text=True)
    results = []
    for identifier, app in registrations(dump):
        if not in_scope(app) or app == keep:
            continue
        result = {'path': str(app), 'bundleID': identifier}
        if not args.dry_run:
            completed = subprocess.run([REGISTRY, '-u', str(app)], capture_output=True, text=True)
            result['exitCode'] = completed.returncode
            if completed.returncode:
                result['error'] = completed.stderr.strip() or completed.stdout.strip()
        results.append(result)
    report = {'kept': str(keep) if keep else None, 'dryRun': args.dry_run, 'registrations': results}
    if not args.dry_run:
        destination = ROOT / 'build/spotlight-registration-cleanup-latest.json'
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 1 if any(item.get('exitCode', 0) for item in results) else 0


if __name__ == '__main__':
    raise SystemExit(main())
