import YAML from "yaml";
import { isSafeNumber } from "lossless-json";
export function documents(text) {
  const docs = YAML.parseAllDocuments(text, {
    version: "1.2",
    uniqueKeys: true,
    intAsBigInt: true,
  });
  for (const doc of docs) {
    if (doc.errors.length) throw doc.errors[0];
    YAML.visit(doc, (_, node) => {
      if (
        YAML.isScalar(node) &&
        typeof node.value === "number" &&
        node.source &&
        !isSafeNumber(node.source.replace(/_/g, ""))
      )
        throw Error("YAML 浮点数无法精确表示；请用字符串保留其字面值。");
    });
    doc.toJS({ maxAliasCount: 50 });
  }
  return docs;
}
