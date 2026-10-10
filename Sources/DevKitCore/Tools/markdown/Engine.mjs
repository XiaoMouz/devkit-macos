import { marked } from "marked";
import sanitize from "sanitize-html";
import { result } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const html = sanitize(marked.parse(i.text), {
    allowedTags: sanitize.defaults.allowedTags.filter((t) => t !== "a"),
    allowedAttributes: {},
    allowedSchemes: [],
  });
  return result(html, {
    html,
    note: "预览不加载外部资源，原始 HTML 经白名单清理。",
  });
};
