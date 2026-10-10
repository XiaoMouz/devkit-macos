import { optimize } from "svgo/browser";
import { result } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  if (
    /<!DOCTYPE|<!ENTITY|<script|<foreignObject|\bon\w+\s*=|(?:href|src)\s*=|url\s*\(|@import/i.test(
      i.text,
    )
  )
    throw Error("SVG 包含脚本、事件、实体或外部引用；请先移除。");
  if (!/<svg[\s>]/.test(i.text)) throw Error("需要 SVG 文档");
  const value = optimize(i.text, { multipass: false }).data;
  return result(value, {
    html: value,
    note: "SVG 外部引用与脚本被拒绝；可以导出 SVG 源文件。",
  });
};
