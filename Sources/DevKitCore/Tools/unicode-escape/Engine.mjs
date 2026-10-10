import { result } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  if (o.operation === "encode")
    return result(
      o.style === "codepoint"
        ? Array.from(
            i.text,
            (c) => "\\u{" + c.codePointAt(0).toString(16) + "}",
          ).join("")
        : i.text
            .split("")
            .map((c) => "\\u" + c.charCodeAt(0).toString(16).padStart(4, "0"))
            .join(""),
    );
  let text = i.text.replace(
    /\\u\{([0-9a-fA-F]{1,6})\}|\\u([0-9a-fA-F]{4})/g,
    (_, a, b) => {
      const n = parseInt(a || b, 16);
      if (n > 0x10ffff) throw Error("码点超出 Unicode 范围");
      return a ? String.fromCodePoint(n) : String.fromCharCode(n);
    },
  );
  if (/\\u/.test(text)) throw Error("Unicode 转义无效");
  if (!text.isWellFormed()) throw Error("UTF-16 代理对无效");
  return result(text);
};
