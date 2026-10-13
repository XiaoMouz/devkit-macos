# Localization and translation contributions

English is the source language. All localizable strings in Swift and JavaScript use English keys. `en.json` is the reference catalog; Simplified Chinese and future languages provide translations of those English messages. Translators do not need to understand Chinese or edit application code.

The app currently supports English and Simplified Chinese. It follows the system language by default. Choose a language in **Settings → General → Language**; application content updates immediately in every open window. Switching does not recreate views or sessions, discard input, change options, close WebSocket connections, or rerun tools. Existing results and execution errors retain their original content; subsequent runs use the new language. The entire application menu bar, standard menu items, and status labels update live. Some macOS-provided dialogs and static Spotlight metadata are cached by the system and update on their next load; they do not require closing the current work.

## Add a language without changing code

The only editable translation source is `Sources/DevKitCore/Resources/Translations/`.

1. Copy `en.json` to a BCP 47 filename such as `fr.json`, `ja.json`, or `pt-BR.json`.
2. Set `id` to the filename without `.json`. Set `name` to the language's own name, such as `Français`. Settings discovers languages from these files automatically.
3. Translate only the values inside `strings`. Keep the English keys unchanged. Preserve positional placeholders such as `{0}` and `{1}`, and named Apple placeholders such as `${text}` and `${applicationName}`. You may reorder placeholders, but must not add, remove, or repeat them. Keep tool IDs, canonical option values, URLs, standards, and user data intact. Spotlight operation words in its command descriptions should match the translated operation labels (for example, `Encode` → `编码` and `base64 encode hello` → `base64 编码 hello`); do not translate the tool name or payload.
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
- Translate semantic display labels such as URL Safe, Hex, request/response header roles, JWT Header/Payload, and Certificate Subject. Keep canonical option values and protocol/algorithm names unchanged. Do not reuse the appearance key Theme for a certificate subject.
- Never translate user input, sample data, source code, binary content, or algorithmic data. Translate result explanations, validation reports, and errors. Do not extract state or locations from translated prose; JSON parser line and column numbers are separate data.
- `LanguageSelection` exposes a synchronized observable language identifier. Translation reads establish SwiftUI dependencies through Observation; selection changes on the main actor. Keep view identity and tool sessions stable: never use `.id(language)` to force a language refresh. Cached catalogs retain English source keys, while time-zone labels are cached per language.
- Store live status text and inline form validation as `LocalizedMessage` so their templates can render in the current language. This includes CLI/AI installation success messages and key/value editor validation. Tool result data is never translated after generation.
- Swift core, CLI, and workers share the same catalogs. The app freezes the chosen language at execution start and passes `DEVKIT_LANGUAGE` explicitly to workers; streaming checksums preserve that same snapshot. The CLI also forwards its language to workers. The CLI accepts `DEVKIT_LANGUAGE=en devkit list`; otherwise it follows its own system language and does not read the app's private preference.
- JavaScript uses `tr(key, ...arguments)` from `Vendor/localization.mjs`. Swift injects translations before evaluating the bundled engines. Escape translated strings and user content before inserting them into HTML previews. Rebuild the Vendor bundle after engine changes; translation-only changes do not require rebundling JavaScript.
- App Intents titles, parameters, summaries, and shortcut phrases keep static English literals. Generated Apple string catalogs localize them. Do not wrap `LocalizedStringResource` or `DisplayRepresentation` metadata in `L10n.tr`, which returns an ordinary String.
- `NativeMenuLocalization` synchronizes menu-bar headings and standard menu-item titles after language changes and native menu rebuilds. It only changes display and accessibility titles; targets, actions, shortcuts, enabled state, and user-supplied document/window/service names remain untouched. Menu notifications schedule a coalesced update on the main run loop’s common modes, including menu tracking; never update synchronously from AppKit’s menu-change callbacks. Accessibility getters can populate menus and reenter AppKit’s key-equivalent lock, so translation only writes accessibility titles/labels. Use only `setAccessibilityTitle`, `setAccessibilityLabel` and a title-change notification when a translated title changes. Some SwiftUI menu items retain their original AXTitle; the localized accessibilityLabel supplies the spoken name. Do not force legacy AX attributes, suppress deprecation warnings, or swizzle framework classes. Menu translations are ordinary English keys in the same JSON catalogs.
- `SWIFT_EMIT_LOC_STRINGS=NO` disables general Swift string extraction. Xcode may still harvest native interpolation and product labels; the generator marks these as non-translatable passthrough entries. JSON remains the sole translation editing entry point. Native catalogs use English as their development language.
- Spotlight operation names and examples use the same translation catalogs through `SpotlightCatalog.operationKeys`. Parsing accepts all contributed languages, including multiword operation phrases, while canonical English values and abbreviations remain valid. Canonical tokens take precedence; otherwise the longest complete translated phrase wins and ambiguous matches fail. Keep operation translations distinct within each tool. Naming/case options share `TextCaseTool.modeTitleKeys` between app controls and Spotlight, including the case-sensitive `UPPERCASE` option value; translate display labels and command words, never change stored values. Language changes update examples without recreating views; legacy aliases remain readable but have no settings editor.
- Add new English messages to every JSON catalog and run the resource check. Do not edit the generated `.xcstrings` files manually.

## Verification

```sh
python3 Scripts/localization.py --check
DEVKIT_LANGUAGE=zh-Hans swift test
DEVKIT_LANGUAGE=en swift test --filter LocalizationTests
DEVKIT_LANGUAGE=zh-Hans zsh Scripts/test-menu-localization.sh
```

Core, session, and packaged integration tests include Chinese report assertions, so run them with an explicit `zh-Hans` environment. `LocalizationTests` covers matching and fallback, catalog completeness, placeholder reordering, preserving user input, every tool's display metadata, English Swift errors, English JavaScript Schema reports, and JSON error locations. It also checks every tool description and field label against all contributed catalogs, and verifies localized JWT/certificate result labels without changing their data. The packaged Spotlight checker verifies every compiled title, parameter, enum display and summary has a translation, allowing only literal search aliases to pass through. See [development commands](development.md) for checking an existing Xcode-built app.

Use Xcode's **DevKit / My Mac / ⌘R** for interaction checks. Cover both languages, search, long parameter labels, input/result actions, error reports, detached windows, worker output after switching languages, and preservation of inputs, options, results, editor state, and in-flight tasks. Return to Follow System without relying on cached `Locale.preferredLanguages` from an earlier per-app override. Spotlight execution also depends on signing and system indexing; successful resource compilation is not an execution check.

## Website and README translations

The documentation keeps Simplified Chinese at `docs/` and English at `docs/en/`, with matching relative page paths. Every public guide and tool reference must exist in both languages. Keep parameters, canonical values, examples, limits, and internal links in sync. The root README links to `README.en.md`; each docs index has a language link.

VitePress locale configuration owns navigation, search labels, and page chrome. `docs/.vitepress/tool-catalog.json` contains Chinese and English names and summaries shared by the sidebar and homepage. The homepage and software demo follow the current documentation locale. Existing app screenshots show Chinese and are identified as such in the English guide; do not synthesize translated screenshots.
