import {
  parseLossless,
  stringifyLossless,
  result,
} from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const value = parseLossless(i.text);
  if (o.operation === "validate") return result("JSON 有效");
  if (o.operation === "tree") {
    const rows = [];
    const walk = (v, p, d) => {
      if (d > 100) throw Error("树深度超过 100");
      if (v !== null && typeof v === "object" && !v.isLosslessNumber) {
        for (const [k, x] of Object.entries(v))
          walk(x, p + "/" + k.replace(/~/g, "~0").replace(/\//g, "~1"), d + 1);
      } else {
        if (rows.length >= 10000) throw Error("树节点超过 10000");
        rows.push({ label: p || "/", value: stringifyLossless(v) });
      }
    };
    walk(value, "", 0);
    return result(rows.map((r) => r.label + " = " + r.value).join("\n"), {
      rows,
    });
  }
  return result(
    stringifyLossless(value, null, o.operation === "minify" ? undefined : 2),
  );
};
