import {
  parseLossless,
  stringifyLossless,
  result,
} from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const rows = [];
  const str = (v) => stringifyLossless(v);
  const walk = (a, b, p, d) => {
    if (d > 100) throw Error("嵌套过深");
    if (rows.length > 10000) throw Error("差异超过 10000 处");
    if (str(a) === str(b)) return;
    if (
      a &&
      b &&
      typeof a === "object" &&
      typeof b === "object" &&
      !a.isLosslessNumber &&
      !b.isLosslessNumber &&
      Array.isArray(a) === Array.isArray(b)
    ) {
      for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) {
        const path = p + "/" + k.replace(/~/g, "~0").replace(/\//g, "~1");
        if (!Object.hasOwn(a, k))
          rows.push({ label: "+ " + path, value: str(b[k]) });
        else if (!Object.hasOwn(b, k))
          rows.push({ label: "− " + path, value: str(a[k]) });
        else walk(a[k], b[k], path, d + 1);
      }
    } else
      rows.push({ label: "~ " + (p || "/"), value: str(a) + " → " + str(b) });
  };
  walk(parseLossless(i.text), parseLossless(i.secondary), "", 0);
  return result(
    rows.length
      ? rows.map((r) => r.label + " " + r.value).join("\n")
      : "两个 JSON 结构相同",
    { rows },
  );
};
