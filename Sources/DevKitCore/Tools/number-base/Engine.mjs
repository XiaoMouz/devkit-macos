import { tr } from '../../../../Vendor/localization.mjs';
import { result } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const s = i.text.trim();
  if (s.length > 10000) throw Error(tr("Integer input exceeds 10,000 digits"));
  const negative = s.startsWith("-"),
    digits = s.replace(/^[+-]/, "");
  const radix = Number(o.from);
  if (!digits) throw Error(tr("Enter an integer"));
  let value = 0n;
  for (const c of digits.toLowerCase()) {
    const n = parseInt(c, 36);
    if (!Number.isInteger(n) || n >= radix)
      throw Error(tr("Contains characters invalid for the source base"));
    value = value * BigInt(radix) + BigInt(n);
  }
  if (negative) value = -value;
  const rows = [2, 8, 10, 16].map((n) => ({
    label: tr("Base {0}", n),
    value: value.toString(n),
  }));
  return result(value.toString(Number(o.to)), { rows });
};
