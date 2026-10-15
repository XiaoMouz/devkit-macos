# Spotlight

Enable tools in **Settings → Spotlight** to choose DevKit actions from system search.

## Enable tools

1. Open **Settings → Spotlight**.
2. Turn on the main switch, then enable the tools you need.
3. Each tool's page includes command examples and supported operations. The help action in the upper-right corner explains first use, Quick Keys, and troubleshooting.

When running from source, Xcode launches **DevKit Debug**, which keeps its settings and Spotlight index separate from the installed release of DevKit. Choose actions from DevKit Debug when testing; you do not need to delete the release app. System actions require valid developer signing. Manage Quick Keys in Spotlight itself; DevKit does not provide Quick Key or command-alias editing fields.

## Try Base64

1. Press `⌘Space`, then `⌘3` to open the actions list.
2. Search for **Base64 Command** and confirm its source is DevKit.
3. Select the action and enter `encode hello`. The expected result is `aGVsbG8=`. Enter `decode aGVsbG8=` to restore `hello`.

Quick Keys are optional. Use Spotlight's Add Quick Key action and enter `base64`; you can then type `base64 encode hello`. For a guided operation, search for **Base64 Encode or Decode**.

If you see only web search or iCloud Drive search, you are still in ordinary search rather than a DevKit action.

## General entry and command language

Select **DevKit Command** and enter a complete tool command. Optionally assign `dk` as its Quick Key in Spotlight, then type `dk` followed by the full command. The guided entry is **DevKit Tool Action**.

Examples follow the app language. English uses `encode`, `decode`, and `format`; translated operation names are also accepted. Tool and algorithm names stay unchanged, such as `base64` and `MD5`. Text case commands accept localized operation names while retaining canonical values such as `camelCase` and `UPPERCASE`.

```text
base64 encode hello
base64 decode aGVsbG8=
json format {"hello":"world"}
uuid 3
hash MD5 hello
text-case camelCase hello world
```

Existing abbreviations such as `b64 dec aGVsbG8=` remain supported. Custom command aliases saved by older versions remain compatible.

`base64 encode --` represents empty text. `base64 encode --  hello` preserves one space before `hello`. Unicode, spaces, and trailing newlines in input are not translated or trimmed.

The app includes English and Simplified Chinese. Adding translation resources also makes the language's operation words available to command parsing. Commands in supported languages remain usable after switching languages, including when system-cached action descriptions have not updated yet.

## Background activity and quitting

Spotlight can temporarily launch DevKit. With no open windows, a menu bar item shows task activity and offers **Open DevKit** and **Quit DevKit**. DevKit quits after 15 idle seconds following the last task. Hidden and minimized workspaces remain open. A Spotlight-only launch does not start update checks or index synchronization.

**System Settings → Login Items & Extensions → Allow in the Background** manages registered login items and background services. DevKit's temporary tasks do not register a persistent service, so they do not appear there. **Settings → General → Background Activity** explains this policy and shows the current Spotlight task count.

## Disable and troubleshoot

Disabling a tool removes its index and prevents execution, although the system may still display registered action names. Clearing the index and disabling tools affects only DevKit. If an action card does not appear, check signing, tool switches, and the action entry before resyncing. Try the same operation in the main window to check the input itself.

See [Apple's Spotlight guide](https://support.apple.com/guide/mac-help/mchl4953dfeb/26/mac/26) for system Quick Key controls.
