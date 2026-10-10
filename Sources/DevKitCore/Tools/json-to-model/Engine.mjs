import { parseLossless, result } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  if (!/^[A-Za-z_$][\w$]*$/.test(o.name)) throw Error("类型名称无效");
  const infer = (v, d = 0) => {
    if (d > 50) throw Error("嵌套过深");
    if (v === null) return "null";
    if (v?.isLosslessNumber) return "number";
    if (Array.isArray(v))
      return v.length
        ? "Array<" +
            [...new Set(v.map((x) => infer(x, d + 1)))].join(" | ") +
            ">"
        : "unknown[]";
    if (typeof v === "object")
      return (
        "{\n" +
        Object.entries(v)
          .map(
            ([k, x]) =>
              "  ".repeat(d + 1) +
              JSON.stringify(k) +
              ": " +
              infer(x, d + 1) +
              ";",
          )
          .join("\n") +
        "\n" +
        "  ".repeat(d) +
        "}"
      );
    return typeof v;
  };
  return result(
    "export type " + o.name + " = " + infer(parseLossless(i.text)) + ";\n",
    { note: "由当前样例推断；未出现的可选字段和更多联合类型需手动补充。" },
  );
};
