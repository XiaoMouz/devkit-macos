# MIME Types

Look up file extensions and MIME types.

CLI: `mime-types`

## Usage

Enter an extension or type identifier such as json. Run to inspect MIME information from the system UTType database.

## Example

Input:

```text
json
```

Result:

```text
MIME: application/json
Extension: json
UTType: public.json
Description: JSON
```

## CLI

```sh
devkit describe mime-types
```

Read from a file:

```sh
devkit run mime-types --input-file ./input.txt
```

## Notes

Available types depend on the current macOS UTType database.
