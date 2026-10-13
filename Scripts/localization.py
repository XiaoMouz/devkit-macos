#!/usr/bin/env python3
"""Validate translation-only contributions and generate Apple's string catalogs.

Run without arguments to synchronize; --check verifies committed generated files.
This script only reads/writes source resources. It never builds or launches an app.
"""
import argparse
import collections
import json
from pathlib import Path
import re
import sys

from localization_sources import source_keys

ROOT = Path(__file__).resolve().parent.parent
TRANSLATIONS = ROOT / 'Sources/DevKitCore/Resources/Translations'
RESOURCES = ROOT / 'DevKit/Resources'
SOURCE = 'en'


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f'Duplicate JSON key: {key}')
        result[key] = value
    return result


def placeholders(value):
    return collections.Counter(re.findall(r'\$\{[A-Za-z][A-Za-z0-9]*\}|\{[0-9]+\}', value))


def load_catalogs():
    catalogs = {}
    for path in sorted(TRANSLATIONS.glob('*.json')):
        value = json.loads(path.read_text(), object_pairs_hook=unique_object)
        code = path.stem
        if value.get('id') != code or not re.fullmatch(r'[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})*', code):
            raise ValueError(f'{path.name}: id must match its BCP 47 filename')
        if not isinstance(value.get('name'), str) or not value['name'].strip():
            raise ValueError(f'{path.name}: a native language name is required')
        if not isinstance(value.get('strings'), dict):
            raise ValueError(f'{path.name}: strings must be an object')
        catalogs[code] = value['strings']
    if SOURCE not in catalogs or 'zh-Hans' not in catalogs:
        raise ValueError('Both zh-Hans and en catalogs are required')
    source = catalogs[SOURCE]
    for code, strings in catalogs.items():
        missing, unknown = source.keys() - strings.keys(), strings.keys() - source.keys()
        if missing or unknown:
            raise ValueError(f'{code}: missing {len(missing)}, unknown {len(unknown)} keys: {sorted(missing | unknown)[:8]}')
        for key, value in strings.items():
            if not isinstance(value, str) or not value.strip():
                raise ValueError(f'{code}: empty or non-string translation for {key!r}')
            if placeholders(value) != placeholders(key):
                raise ValueError(f'{code}: placeholders do not match for {key!r}')
            if code == SOURCE and value != key:
                raise ValueError(f'{code}: English source value must match its key: {key!r}')
    for path, key in source_keys(ROOT):
        if key not in source:
            raise ValueError(f'{path.relative_to(ROOT)}: translation key is missing: {key!r}')
    return catalogs


def generated_catalog(catalogs, shortcuts):
    strings = {}
    for key in sorted(catalogs[SOURCE]):
        if ('${applicationName}' in key) != shortcuts:
            continue
        # App Intents and native menus use Apple's catalogs. Runtime Swift/JS
        # strings use the same translations directly, without printf evaluation.
        strings[key] = {
            'extractionState': 'manual',
            'localizations': {code: {'stringUnit': {'state': 'translated', 'value': values[key]}}
                              for code, values in sorted(catalogs.items())},
        }
    if not shortcuts:
        # Native framework interpolation and product/encoding labels are literal
        # passthrough values. Xcode may harvest them even with Swift extraction off.
        for key in ('%@', 'DevKit', 'UTF-8', '0.2.0 · macOS 26+'):
            strings[key] = {'extractionState': 'manual', 'shouldTranslate': False}
    return json.dumps({'sourceLanguage': 'en', 'strings': dict(sorted(strings.items())), 'version': '1.0'},
                      ensure_ascii=False, indent=2) + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='fail if generated native catalogs are stale')
    args = parser.parse_args()
    catalogs = load_catalogs()
    for filename, shortcuts in [('Localizable.xcstrings', False), ('AppShortcuts.xcstrings', True)]:
        path = RESOURCES / filename
        expected = generated_catalog(catalogs, shortcuts)
        if args.check:
            if not path.exists() or json.loads(path.read_text()) != json.loads(expected):
                raise ValueError(f'{path.relative_to(ROOT)} is stale; run python3 Scripts/localization.py')
        else:
            path.write_text(expected)
    print(f'Validated {len(catalogs)} languages × {len(catalogs[SOURCE])} messages; native catalogs are current.')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
