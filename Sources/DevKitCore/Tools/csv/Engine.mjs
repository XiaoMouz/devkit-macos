import {
  csvParse,
  csvStringify,
  pretty,
  result,
} from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const rows = csvParse(i.text, o.delimiter === "tab" ? "\t" : o.delimiter);
  if (o.operation === "transpose") {
    const n = Math.max(0, ...rows.map((r) => r.length));
    if (n > 10000) throw Error("列数过多");
    return result(
      csvStringify(
        Array.from({ length: n }, (_, x) => rows.map((r) => r[x] ?? "")),
      ),
    );
  }
  return result(
    o.operation === "json"
      ? pretty(rows)
      : csvStringify(rows, o.delimiter === "tab" ? "\t" : o.delimiter),
    {
      rows: rows
        .slice(0, 1000)
        .map((r, n) => ({ label: String(n + 1), value: r.join("  |  ") })),
      note: rows.length + " 行 · 表格预览最多 1000 行",
    },
  );
};
