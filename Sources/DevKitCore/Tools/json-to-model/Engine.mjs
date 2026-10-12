import { tr } from '../../../../Vendor/localization.mjs';
import * as prettier from "prettier/standalone";
import * as typescript from "prettier/plugins/typescript";
import * as estree from "prettier/plugins/estree";
import { parseLossless, result } from "../../../../Vendor/common.mjs";
export default async (i, o) => {
  if (!/^[A-Za-z_$][\w$]*$/.test(o.name)) throw Error(tr("Invalid type name"));
  const infer = (v, d = 0) => {
    if (d > 50) throw Error(tr("Nesting is too deep"));
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
    await prettier.format("export type " + o.name + " = " + infer(parseLossless(i.text)) + ";\n", { parser: "typescript", plugins: [typescript, estree] }),
    { note: tr("Inferred from the current sample. Add missing optional fields and additional union types manually.") },
  );
};
