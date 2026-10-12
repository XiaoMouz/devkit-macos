# Localization and translation contributions

English is the source language. All localizable strings in Swift and JavaScript use English keys. `en.json` is the reference catalog; Simplified Chinese and future languages provide translations of those English messages. Translators do not need to understand Chinese or edit application code.

The app currently supports English and Simplified Chinese. It follows the system language by default. Choose a language in **Settings → General → Language**, then quit and reopen DevKit. A language is fixed for the process lifetime so windows, cached metadata, native menus, and Spotlight remain consistent. Save any unexported content before quitting.

## Add a language without changing code

The only editable translation source is `Sources/DevKitCore/Resources/Translations/`.

1. Copy `en.json` to a BCP 47 filename such as `fr.json`, `ja.json`, or `pt-BR.json`.
2. Set `id` to the filename without `.json`. Set `name` to the language's own name, such as `Français`. Settings discovers languages from these files automatically.
3. Translate only the values inside `strings`. Keep the English keys unchanged. Preserve positional placeholders such as `{0}` and `{1}`, and named Apple placeholders such as `${text}` and `${applicationName}`. You may reorder placeholders, but must not add, remove, or repeat them. Keep commands, option names, URLs, standards, and code examples intact.
4. Run `python3 Scripts/localization.py` from the repository root to synchronize the native string catalogs. This command only maintains resources; it does not build or launch the app. Contributors may also submit only the JSON file and ask a maintainer to synchronize it.
5. Commit the JSON file and generated `DevKit/Resources/Localizable.xcstrings` and `AppShortcuts.xcstrings`. No Swift, JavaScript, registry, Info.plist, Xcode project, or XcodeGen changes are needed. Verify with `python3 Scripts/localization.py --check`.

Example French entries:

```json
{
  "id": "fr",
  "name": "Français",
  "strings": {
    "Copy": "Copier",
    "Font Size {0}": "Taille de police {0}",
    "Showing the first {0} of {1} issues.": "Affichage des {0} premiers problèmes sur {1}."
  }
}
```

This is only an illustration. A submitted catalog must contain the full set of keys copied from `en.json`.

The validator rejects duplicate JSON keys, empty translations, unknown or missing keys, invalid language IDs, and mismatched placeholders. It also checks literal Swift/JavaScript translation calls against the source catalog and detects stale generated resources. English values must match their keys. Runtime fallback is English, then the English source key, so a missing resource cannot produce a blank label.

Language matching tries the exact identifier, then a compatible variant selected by macOS, then English. Unsupported scripts do not silently switch to another script. Changing an English key requires updating code and every catalog; changing a translation should never change its key. The format supports positional substitution, not ICU plural or select expressions. Use count-neutral wording such as `Files: {0}` when needed.

## Developer integration

- Use `L10n.tr("Exported to \(folder) (files: \(count))")` for Swift messages. Interpolation produces `{0}` and `{1}`. The template is looked up first, then substituted in one pass; percent signs, braces, and user data inside arguments are never reinterpreted.
- Use `L10n.text(key)` only for developer-authored dynamic keys. Tool names, summaries, and category titles resolve when displayed. The legacy category `rawValue` strings remain unchanged solely for Codable/CLI compatibility; they are not translation keys. Tool IDs, field IDs, option values, JSON keys, and error codes remain stable. Search retains English and Chinese metadata.
- Never translate user input, sample data, source code, binary content, or algorithmic data. Translate result explanations, validation reports, and errors. Do not extract state or locations from translated prose; JSON parser line and column numbers are separate data.
- Swift core, CLI, and workers share the same catalogs. The app and CLI pass `DEVKIT_LANGUAGE` explicitly to their workers. The CLI accepts `DEVKIT_LANGUAGE=en devkit list`; otherwise it follows its own system language and does not read the app's private preference.
- JavaScript uses `tr(key, ...arguments)` from `Vendor/localization.mjs`. Swift injects translations before evaluating the bundled engines. Escape translated strings and user content before inserting them into HTML previews. Rebuild the Vendor bundle after engine changes; translation-only changes do not require rebundling JavaScript.
- App Intents titles, parameters, summaries, and shortcut phrases keep static English literals. Generated Apple string catalogs localize them. Do not wrap `LocalizedStringResource` or `DisplayRepresentation` metadata in `L10n.tr`, which returns an ordinary String.
- `SWIFT_EMIT_LOC_STRINGS=NO` disables general Swift string extraction. Xcode may still harvest native interpolation and product labels; the generator marks these as non-translatable passthrough entries. JSON remains the sole translation editing entry point. Native catalogs use English as their development language.
- Add new English messages to every JSON catalog and run the resource check. Do not edit the generated `.xcstrings` files manually.

## Verification

```sh
python3 Scripts/localization.py --check
DEVKIT_LANGUAGE=zh-Hans swift test
DEVKIT_LANGUAGE=en swift test --filter LocalizationTests
```

Core, session, and packaged integration tests include Chinese report assertions, so run them with an explicit `zh-Hans` environment. `LocalizationTests` covers matching and fallback, catalog completeness, placeholder reordering, preserving user input, every tool's display metadata, English Swift errors, English JavaScript Schema reports, and JSON error locations. See [development commands](development.md) for checking an existing Xcode-built app.

Use Xcode's **DevKit / My Mac / ⌘R** for interaction checks. Cover both languages, search, long parameter labels, input/result actions, error reports, detached windows, and worker output after switching languages. Spotlight execution also depends on signing and system indexing; successful resource compilation is not an execution check.
