import { tr } from '../../../../Vendor/localization.mjs';
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
      throw Error(tr("JSON Pointer must be empty or start with /"));
    value = data;
    for (const p of o.path === "" ? [] : o.path.slice(1).split("/")) {
      if (/~(?![01])/g.test(p)) throw Error(tr("Invalid Pointer escape"));
      const k = p.replace(/~1/g, "/").replace(/~0/g, "~");
      if (
        value === null ||
        typeof value !== "object" ||
        !Object.hasOwn(value, k)
      )
        throw Error(tr("Path does not exist"));
      value = value[k];
    }
  } else {
    if (!o.path.trim()) throw Error(tr("Enter a JSONPath query, such as $ or $.users[0].name"));
    value = JSONPath({ path: o.path, json: data, eval: false, wrap: true });
  }
  return result(stringifyLossless(value, null, 2));
};
