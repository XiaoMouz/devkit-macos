#!/usr/bin/env python3
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('sign_app', Path(__file__).with_name('sign-app.py'))
signing = importlib.util.module_from_spec(spec)
spec.loader.exec_module(signing)

class SigningTests(unittest.TestCase):
    def test_empty_keychain_is_preview_only(self):
        self.assertEqual(signing.choose_identity([]), '-')
        with self.assertRaises(ValueError): signing.choose_identity([], required=True)
        with self.assertRaises(ValueError): signing.choose_identity([], '-', True)
    def test_single_developer_identity_is_preserved(self):
        identity = 'A' * 40
        candidates = signing.identities(f'  1) {identity} "Apple Development: Test (TEAM)"\n     1 valid identities found')
        self.assertEqual(signing.choose_identity(candidates, required=True), identity)
        self.assertEqual(signing.choose_identity(candidates, identity.lower()), identity)
    def test_ambiguous_or_unknown_identity_fails(self):
        candidates = [('A' * 40, 'Apple Development: A'), ('B' * 40, 'Developer ID Application: B')]
        with self.assertRaises(ValueError): signing.choose_identity(candidates)
        with self.assertRaises(ValueError): signing.choose_identity(candidates, 'missing')
        self.assertEqual(signing.choose_identity(candidates, 'Developer ID Application: B'), 'B' * 40)
    def test_distribution_and_nonapple_identities_are_not_auto_selected(self):
        value = f'  1) {"C" * 40} "Local Test"\n  2) {"D" * 40} "Apple Distribution: Test"'
        self.assertEqual(signing.identities(value), [])

if __name__ == '__main__': unittest.main()
