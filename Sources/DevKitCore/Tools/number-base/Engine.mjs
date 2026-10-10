import { result } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const s = i.text.trim();
  if (s.length > 10000) throw Error("整数输入超过 10000 位");
  const negative = s.startsWith("-"),
    digits = s.replace(/^[+-]/, "");
  const radix = Number(o.from);
  if (!digits) throw Error("请输入整数");
  let value = 0n;
  for (const c of digits.toLowerCase()) {
    const n = parseInt(c, 36);
    if (!Number.isInteger(n) || n >= radix)
      throw Error("包含不适用于源进制的字符");
    value = value * BigInt(radix) + BigInt(n);
  }
  if (negative) value = -value;
  const rows = [2, 8, 10, 16].map((n) => ({
    label: n + " 进制",
    value: value.toString(n),
  }));
  return result(value.toString(Number(o.to)), { rows });
};
