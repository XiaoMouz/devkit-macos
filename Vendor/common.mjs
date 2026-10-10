import {
  parse as parseLossless,
  stringify as stringifyLossless,
  isLosslessNumber,
  isSafeNumber,
} from "lossless-json";
export { parseLossless, stringifyLossless };
export const result = (text, extras = {}) => ({
  text: String(text),
  rows: [],
  artifacts: [],
  ...extras,
});
export const pretty = (value) => JSON.stringify(value, null, 2);
export function safeJSON(text) {
  return parseLossless(text, undefined, {
    parseNumber: (s) => {
      const n = Number(s);
      if (!isSafeNumber(s))
        throw Error("数值超出此操作的精确范围。请用 JSON 工作台保留原始数值。");
      if (s.replace(/[-+.eE0-9]/g, "")) throw Error("无效数字");
      return n;
    },
  });
}
export const escapeHTML = (s) =>
  String(s).replace(
    /[&<>"']/g,
    (c) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[
        c
      ],
  );
export function csvStringify(rows, delimiter = ",") {
  return rows
    .map((row) =>
      row
        .map((v) => {
          const s = String(v ?? "");
          return /["\r\n]/.test(s) || s.includes(delimiter)
            ? '"' + s.replace(/"/g, '""') + '"'
            : s;
        })
        .join(delimiter),
    )
    .join("\r\n");
}
