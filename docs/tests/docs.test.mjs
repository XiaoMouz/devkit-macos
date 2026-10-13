import assert from "node:assert/strict";
import { readFile, readdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import test from "node:test";
import {
  demoTools,
  runDemo,
  jsonTokens,
} from "../.vitepress/theme/demo-tools.mjs";

const docs = fileURLToPath(new URL("../", import.meta.url));
async function pages(dir, prefix = "") {
  const result = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    if (
      entry.name.startsWith(".") ||
      ["node_modules", "public", "en", "tests"].includes(entry.name)
    )
      continue;
    const relative = path.join(prefix, entry.name);
    if (entry.isDirectory())
      result.push(...(await pages(path.join(dir, entry.name), relative)));
    else if (entry.name.endsWith(".md")) result.push(relative);
  }
  return result.sort();
}

test("every Chinese documentation page has an English counterpart", async () => {
  assert.deepEqual(await pages(docs), await pages(path.join(docs, "en")));
});

test("all 48 catalog entries have bilingual metadata and matching reference parameters", async () => {
  const catalog = JSON.parse(
    await readFile(path.join(docs, ".vitepress/tool-catalog.json"), "utf8"),
  );
  const ids = catalog.flatMap((group) => group.tools.map((tool) => tool.id));
  assert.equal(ids.length, 48);
  assert.equal(new Set(ids).size, 48);
  for (const group of catalog) {
    assert.ok(group.name && group.nameEn);
    for (const tool of group.tools) {
      assert.ok(
        tool.name && tool.nameEn && tool.summary && tool.summaryEn,
        tool.id,
      );
      const [zh, en] = await Promise.all(
        ["", "en/"].map((locale) =>
          readFile(path.join(docs, `${locale}tools/${tool.id}.md`), "utf8"),
        ),
      );
      const parameters = (text) =>
        text
          .split("\n")
          .filter((line) => line.startsWith("| `"))
          .map((line) => {
            const cells = line.split("|");
            return [
              cells[1].trim(),
              [...cells[4].matchAll(/`([^`]+)`/g)].map((match) => match[1]),
            ];
          });
      assert.deepEqual(parameters(en), parameters(zh), tool.id);
    }
  }
});

test("JSON formatting preserves input values and rejects invalid syntax", () => {
  const input = '{"text":"<script>alert(1)</script>","value":1,"ok":true}';
  assert.deepEqual(
    JSON.parse(runDemo("json", input, "format")),
    JSON.parse(input),
  );
  assert.equal(runDemo("json", ' { "a": 1 } ', "minify"), '{"a":1}');
  assert.equal(runDemo("json", input, "validate"), "valid-json");
  assert.throws(() => runDemo("json", '{"a":}', "format"));
  const formatted = runDemo("json", input, "format");
  assert.equal(
    jsonTokens(formatted)
      .map((token) => token.value)
      .join(""),
    formatted,
  );
});

test("Base64 handles Unicode, whitespace, empty text, and invalid binary", () => {
  for (const text of ["hello", "  你好 👩‍💻\n", "", "\u0000"]) {
    const encoded = runDemo("base64", text, "encode");
    assert.equal(encoded, Buffer.from(text).toString("base64"));
    assert.equal(runDemo("base64", encoded, "decode"), text);
  }
  assert.throws(() => runDemo("base64", "%%%", "decode"));
  assert.throws(() => runDemo("base64", "/w==", "decode"));
});

test("URL demo preserves plus signs and Unicode and rejects malformed escapes", () => {
  assert.equal(
    runDemo("url-codec", "a + b/你好", "encode"),
    "a%20%2B%20b%2F%E4%BD%A0%E5%A5%BD",
  );
  assert.equal(runDemo("url-codec", "a%20%2B%20b", "decode"), "a + b");
  assert.throws(() => runDemo("url-codec", "%ZZ", "decode"));
});

test("timestamps use explicit units and reject invalid values", () => {
  assert.ok(
    runDemo("timestamp", "1700000000", "seconds").startsWith(
      "2023-11-14T22:13:20.000Z",
    ),
  );
  assert.ok(
    runDemo("timestamp", "1700000000001", "milliseconds").startsWith(
      "2023-11-14T22:13:20.001Z",
    ),
  );
  for (const input of ["", "not a date", "1.5", "999999999999999999"])
    assert.throws(() => runDemo("timestamp", input, "seconds"));
});

test("UUID generates three distinct v4 identifiers and case conversion works", () => {
  const ids = runDemo("uuid", "", "v4").split("\n\n");
  assert.equal(new Set(ids).size, 3);
  for (const id of ids)
    assert.match(
      id,
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
    );
  assert.equal(
    runDemo("text-case", "helloWorld example", "snake"),
    "hello_world_example",
  );
  assert.equal(runDemo("text-case", "hello world", "camel"), "helloWorld");
  assert.equal(runDemo("text-case", "", "camel"), "");
  assert.equal(new Set(demoTools.map((tool) => tool.id)).size, 6);
});

test("terminal playback examples show accurate, copyable CLI results", async () => {
  const { terminalExamples } =
    await import("../.vitepress/theme/terminal-examples.mjs");
  assert.deepEqual(
    terminalExamples.map((example) => example.id),
    ["json", "base64", "url-codec"],
  );
  assert.equal(
    terminalExamples[0].output,
    '{\n  "name": "DevKit",\n  "tools": 48\n}',
  );
  assert.equal(terminalExamples[1].output, "SGVsbG8sIERldktpdA==");
  assert.equal(terminalExamples[2].output, "hello%20world%20%2B%20DevKit");
  for (const example of terminalExamples) {
    assert.ok(example.command.includes(`'${example.input}'`));
    assert.ok(
      example.command.endsWith(`devkit run ${example.id} --format text`),
    );
    assert.ok(example.command.includes("\\\n  |"));
  }
});

test("tool search normalizes input, ranks exact names, and supports multiple literal terms", async () => {
  const { searchTools } = await import("../.vitepress/theme/tool-search.mjs");
  const catalog = JSON.parse(
    await readFile(path.join(docs, ".vitepress/tool-catalog.json"), "utf8"),
  );
  const tools = catalog.flatMap((group) => group.tools);
  assert.equal(searchTools(tools, "　ＪＳＯＮ　")[0].id, "json");
  assert.deepEqual(
    searchTools(tools, "schema type").map((tool) => tool.id),
    ["json"],
  );
  assert.equal(searchTools(tools, "UTF-8 encode")[0].id, "base64");
  assert.equal(searchTools(tools, "证书")[0].id, "pem-certificate");
  assert.deepEqual(searchTools(tools, "[broken.*"), []);
  assert.equal(searchTools(tools, "  "), tools);
});
