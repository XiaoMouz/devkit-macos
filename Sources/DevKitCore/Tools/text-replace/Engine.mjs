import { result } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  if (!o.search) throw Error("查找内容不能为空");
  const s = o.regex
    ? i.text.replace(new RegExp(o.search, o.flags), o.replacement)
    : i.text.split(o.search).join(o.replacement);
  return result(s, { note: "输入保持原样；结果可以复制或再次编辑。" });
};
