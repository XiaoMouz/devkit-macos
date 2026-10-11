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
  const discarded = o.language === "css" && !out.trim() && i.text.replace(/\/\*[\s\S]*?\*\//g, "").trim();
  const note = o.language === "html" ? " HTML 按浏览器语法解析，可能自动补齐或修复标签；请核对结果。"
    : o.language === "css" ? " CSS 使用容错解析；无效声明可能被丢弃，请核对结果。" : "";
  return result(out, {
    note: "原文 " + i.text.length + " 字符 → " + out.length + " 字符" + note,
    ...(discarded ? {report: {state: "warning", title: "没有可保留的 CSS 内容", detail: "输入中的无效或空规则已被解析器丢弃。请检查语法后重试。", metrics: []}} : {}),
  });
};
