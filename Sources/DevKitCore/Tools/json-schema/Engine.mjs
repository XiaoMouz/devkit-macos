import Ajv from "ajv/dist/2020.js";
import addFormats from "ajv-formats";
import { safeJSON, result } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const ajv = new Ajv({ allErrors: true, strict: true, verbose: false });
  addFormats(ajv);
  const validate = ajv.compile(safeJSON(i.secondary));
  const valid = validate(safeJSON(i.text));
  const rows = (validate.errors || [])
    .slice(0, 500)
    .map((e) => ({
      label: e.instancePath || "/",
      value: e.message + " [" + e.keyword + "]",
    }));
  return result(
    valid
      ? "校验通过 · Draft 2020-12"
      : rows.map((r) => r.label + ": " + r.value).join("\n"),
    { rows, note: "无远程引用加载；校验不改写输入。" },
  );
};
