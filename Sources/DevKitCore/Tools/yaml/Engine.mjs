import { documents } from "../../../../Vendor/yaml.mjs";
import { result, stringifyLossless } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const docs = documents(i.text);
  return result(
    o.operation === "validate"
      ? "YAML 有效 · " + docs.length + " 个文档"
      : o.operation === "json"
        ? stringifyLossless(
            docs.map((d) => d.toJS({ maxAliasCount: 50 })),
            null,
            2,
          )
        : docs.map((d) => d.toString()).join("---\n"),
  );
};
