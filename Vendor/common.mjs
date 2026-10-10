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
export function csvParse(s, delimiter = ",") {
  if (delimiter.length !== 1) throw Error("分隔符必须为一个字符。");
  const rows = [],
    row = [];
  let field = "",
    quoted = false,
    closed = false;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (quoted) {
      if (c === '"') {
        if (s[i + 1] === '"') {
          field += '"';
          i++;
        } else {
          quoted = false;
          closed = true;
        }
      } else field += c;
    } else if (c === delimiter) {
      row.push(field);
      field = "";
      closed = false;
    } else if (c === "\n" || c === "\r") {
      if (c === "\r" && s[i + 1] === "\n") i++;
      row.push(field);
      rows.push(row.splice(0));
      field = "";
      closed = false;
    } else if (c === '"' && !field && !closed) quoted = true;
    else {
      if (closed || c === '"') throw Error("CSV 引号位置无效。");
      field += c;
    }
  }
  if (quoted) throw Error("CSV 引号未闭合。");
  if (field || row.length || closed || (!rows.length && s)) {
    row.push(field);
    rows.push(row);
  }
  if (rows.length > 100000) throw Error("CSV 超过 100000 行。");
  return rows;
}
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
