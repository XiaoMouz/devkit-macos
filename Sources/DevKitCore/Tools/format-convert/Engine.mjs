import { documents } from "../../../../Vendor/yaml.mjs";
import YAML from "yaml";
import * as TOML from "smol-toml";
import {
  safeJSON,
  pretty,
  result,
  csvParse,
  csvStringify,
} from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const v =
    o.from === "json"
      ? safeJSON(i.text)
      : o.from === "yaml"
        ? (() => {
            const docs = documents(i.text);
            if (docs.length !== 1) throw Error("格式转换只接受一个 YAML 文档");
            return docs[0].toJS({ maxAliasCount: 50 });
          })()
        : o.from === "toml"
          ? TOML.parse(i.text, { integersAsBigInt: "asNeeded" })
          : csvParse(i.text);
  const seen = new Set();
  const validate = (v, d = 0) => {
    if (d > 100) throw Error("嵌套过深");
    if (v && typeof v === "object") {
      if (seen.has(v)) throw Error("循环引用不可转换");
      seen.add(v);
      if (v instanceof Date)
        throw Error("日期类型无法无损转换，请先明确转换为字符串");
      for (const x of Object.values(v)) validate(x, d + 1);
      seen.delete(v);
    } else if (typeof v === "bigint") {
      if (
        v > BigInt(Number.MAX_SAFE_INTEGER) ||
        v < BigInt(Number.MIN_SAFE_INTEGER)
      )
        throw Error("整数超出目标转换的安全精度范围");
    } else if (
      typeof v === "number" &&
      (!Number.isFinite(v) || (Number.isInteger(v) && !Number.isSafeInteger(v)))
    )
      throw Error("数值精度不可无损表达");
  };
  validate(v);
  const normalize = (x) =>
    typeof x === "bigint"
      ? Number(x)
      : Array.isArray(x)
        ? x.map(normalize)
        : x && typeof x === "object"
          ? Object.fromEntries(
              Object.entries(x).map(([k, v]) => [k, normalize(v)]),
            )
          : x;
  const converted = normalize(v);
  let s;
  if (o.to === "csv") {
    if (
      !Array.isArray(v) ||
      v.some((r) => !Array.isArray(r) || r.some((x) => typeof x === "object"))
    )
      throw Error("CSV 目标只接受二维标量数组；不会丢弃嵌套字段");
    s = csvStringify(v);
  } else
    s =
      o.to === "json"
        ? pretty(converted)
        : o.to === "yaml"
          ? YAML.stringify(converted)
          : TOML.stringify(converted);
  return result(s, {
    note:
      o.to === "csv" || o.from === "csv"
        ? "CSV 单元格按文本处理，无法保留数值、布尔与空值类型。"
        : undefined,
  });
};
