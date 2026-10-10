#!/usr/bin/env python3
"""Remove duplicate DevKit registrations only; never reset the system-wide database."""
import argparse
import json
from pathlib import Path
import re
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--include-installed', action='store_true', help='Also unregister ~/Applications/DevKit.app')
args = parser.parse_args()
registry = '/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'
root = Path(__file__).resolve().parents[1]
installed = Path.home() / 'Applications/DevKit.app'
dump = subprocess.check_output([registry, '-dump'], text=True)
results = []
for block in dump.split('bundle id:'):
    if not re.search(r'^identifier:\s+app\.devkit\.(?:macos|preview)\s*$', block, re.M):
        continue
    match = re.search(r'^path:\s+(.+?)\s+\(0x[0-9a-f]+\)', block, re.M)
    if not match:
        continue
    path = Path(match.group(1))
    if path != installed and not path.is_relative_to(root):
        continue
    if path == installed and not args.include_installed:
        continue
    completed = subprocess.run([registry, '-u', str(path)], capture_output=True, text=True)
    results.append({'path': str(path), 'exitCode': completed.returncode})
report = root / 'build/spotlight-registration-cleanup-latest.json'
report.parent.mkdir(parents=True, exist_ok=True)
report.write_text(json.dumps(results, indent=2))
print(json.dumps(results, ensure_ascii=False, indent=2))
raise SystemExit(1 if any(item['exitCode'] for item in results) else 0)
