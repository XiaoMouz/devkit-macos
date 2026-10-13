# Eight JSON operations

All eight operations live in JSON Workspace. Switch operations from the toolbar; the source JSON stays in place. Structural comparison and Schema validation have separate second inputs.

![JSON formatting and collapsible preview; screenshot shown in Chinese](/images/json-workspace.png)

## Format and minify

Enter `{"name":"DevKit","users":[{"id":1,"name":"Ada"}]}`, choose Format, and run. The result defaults to a collapsible view. Use triangles to expand or collapse objects and arrays. Array labels show element counts; these preview labels are not included when copying or exporting JSON.

Minify removes formatting whitespace for more compact JSON. If formatting or minification fails, check quotes, commas, and brackets.

## Validate syntax and list paths

Syntax validation shows success or failure with error details. The path list helps locate nested fields. Large JSON previews show at most 10,000 nodes and may truncate long values. You can still copy or export the complete result.

## Query a path

1. Choose the query operation.
2. Select JSONPath or JSON Pointer.
3. Enter a path and run.

For the example above:

| Syntax | Path | Result |
| --- | --- | --- |
| JSONPath | `$.users[0].name` | Ada, the first user's name |
| JSON Pointer | `/users/0/name` | The same name |
| JSON Pointer | Empty path | The entire document |

JSONPath requires a path. Switching query syntax resets its default path, so check the path again after switching.

## Structural comparison

Choose structural comparison. Put the old JSON in the source input and the new JSON in the comparison input. Run to see counts of additions, removals, and changes, then inspect the path, highlighted, or text views. This compares JSON structure; use [Text Diff](../tools/text-diff.md) for ordinary line-by-line text differences.

For example, comparing `{"version":1}` with `{"version":2,"enabled":true}` shows a changed version and an added field.

## Schema validation

Choose Schema validation and place rules in the second input, for example:

```json
{
  "type": "object",
  "required": ["name"],
  "properties": {"name": {"type": "string"}}
}
```

`{"name":"DevKit"}` passes; `{"name":42}` fails the string type requirement. The report explains the reason in the interface language and highlights the data and matching rule. Missing fields highlight their parent object. Draft 2020-12 is supported. Successful execution does not itself mean validation passed.

## TypeScript types

Choose TypeScript type generation, enter a root type name such as `ApiResponse`, and run. Inferred types describe only the sample data. Add optional fields, business enums, and other response shapes according to your API contract.

## Use from the terminal

```sh
devkit run json --input-file response.json --option operation=minify --format text
devkit run json --input-file response.json --option operation=query --option 'path=$.users[0].name'
devkit run json --input-file old.json --secondary-file new.json --option operation=diff
devkit run json --input-file response.json --secondary-file schema.json --option operation=schema
```

See [JSON reference](../tools/json.md) for parameters and [CLI & AI](../cli-and-ai.md) for complex inputs.
