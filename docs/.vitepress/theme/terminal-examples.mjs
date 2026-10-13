import { runDemo } from "./demo-tools.mjs";

// Fixed, copyable CLI examples. Their displayed results use the same browser
// conversions as the interactive workbench; no shell or network is invoked.
export const terminalExamples = [
  {
    id: "json",
    label: "JSON",
    zh: "格式化 JSON",
    en: "Format JSON",
    input: '{"name":"DevKit","tools":48}',
    operation: "format",
    command: `printf '%s' '{"name":"DevKit","tools":48}' \\\n  | devkit run json --format text`,
  },
  {
    id: "base64",
    label: "Base64",
    zh: "编码文本",
    en: "Encode text",
    input: "Hello, DevKit",
    operation: "encode",
    command: `printf '%s' 'Hello, DevKit' \\\n  | devkit run base64 --format text`,
  },
  {
    id: "url-codec",
    label: "URL",
    zh: "编码 URL 参数",
    en: "Encode a URL component",
    input: "hello world + DevKit",
    operation: "encode",
    command: `printf '%s' 'hello world + DevKit' \\\n  | devkit run url-codec --format text`,
  },
].map((example) => ({
  ...example,
  output: runDemo(example.id, example.input, example.operation),
}));
