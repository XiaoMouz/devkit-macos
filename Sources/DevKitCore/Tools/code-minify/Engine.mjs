import { minify } from "terser";
import { minify as css } from "csso";
import { parse, parseFragment, serialize } from "parse5";
function html(s) {
  const doc = /<!doctype|<html[\s>]/i.test(s) ? parse(s) : parseFragment(s);
  const walk = (node, raw = false) => {
    raw = raw || ["pre", "textarea", "script", "style"].includes(node.tagName);
    if (node.childNodes) {
      node.childNodes = node.childNodes.filter(
        (n) => n.nodeName !== "#comment",
      );
      for (const c of node.childNodes) {
        if (c.nodeName === "#text" && !raw)
          c.value = c.value.replace(/\s+/g, " ");
        walk(c, raw);
      }
    }
  };
  walk(doc);
  return serialize(doc);
}
import { result } from "../../../../Vendor/common.mjs";
export default async (i, o) => {
  const out =
    o.language === "javascript"
      ? (
          await minify(i.text, {
            compress: false,
            mangle: false,
            format: { comments: false },
          })
        ).code
      : o.language === "css"
        ? css(i.text).css
        : await html(i.text, {
            collapseWhitespace: true,
            removeComments: true,
            conservativeCollapse: true,
          });
  return result(out, {
    note: "原文 " + i.text.length + " 字符 → " + out.length + " 字符",
  });
};
