#!/usr/bin/env python3
"""Check the compiled actions Spotlight consumes, not just the Swift declarations."""
import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('app', type=Path)
args = parser.parse_args()
metadata = json.loads((args.app / 'Contents/Resources/Metadata.appintents/extract.actionsdata').read_text())
expected = {
    'Base64CommandIntent': {'command'},
    'Base64GuidedIntent': {'operation', 'text'},
    'DevKitCommandIntent': {'command'},
    'DevKitToolIntent': {'action', 'text'},
}
actions = metadata['actions']
public = {key for key, value in actions.items() if value.get('isDiscoverable')}
assert public == set(expected), f'Unexpected public actions: {public}'
shortcuts = {item['actionIdentifier'] for item in metadata['autoShortcuts']}
assert shortcuts == set(expected), f'Unexpected App Shortcuts: {shortcuts}'
for key, parameters in expected.items():
    action = actions[key]
    summary = action['actionConfiguration']['actionSummary']['wrapper']['summaryString']
    assert parameters <= set(summary['parameterIdentifiers']), f'Missing summary parameters: {key}'
    assert action['supportedModes'] & 1 and not action['openAppWhenRun'], f'Not a background action: {key}'
print('PASS: 4 discoverable background actions, complete parameter summaries and App Shortcuts')
