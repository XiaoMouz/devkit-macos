import { parse, stringify } from "smol-toml";
import { result, pretty } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const value = parse(i.text, { integersAsBigInt: true });
  return result(
    o.operation === "validate"
      ? "TOML 有效 · 1.1"
      : o.operation === "json"
        ? JSON.stringify(
            value,
            (_, v) => (typeof v === "bigint" ? v.toString() : v),
            2,
          )
        : stringify(value),
    {
      note:
        o.operation === "json"
          ? "TOML 整数以十进制字符串输出，避免 JavaScript 精度损失。"
          : undefined,
    },
  );
};
