import { JSONPath } from "jsonpath-plus";
import {
  parseLossless,
  stringifyLossless,
  result,
} from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const data = parseLossless(i.text);
  let value;
  if (o.syntax === "pointer") {
    if (o.path !== "" && !o.path.startsWith("/"))
      throw Error("JSON Pointer 必须为空或以 / 开头");
    value = data;
    for (const p of o.path === "" ? [] : o.path.slice(1).split("/")) {
      if (/~(?![01])/g.test(p)) throw Error("无效 Pointer 转义");
      const k = p.replace(/~1/g, "/").replace(/~0/g, "~");
      if (
        value === null ||
        typeof value !== "object" ||
        !Object.hasOwn(value, k)
      )
        throw Error("路径不存在");
      value = value[k];
    }
  } else
    value = JSONPath({ path: o.path, json: data, eval: false, wrap: true });
  return result(stringifyLossless(value, null, 2));
};
