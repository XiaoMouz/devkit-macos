import { result } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  if (o.operation === "encode") return result(JSON.stringify(i.text));
  const s = JSON.parse(i.text);
  if (typeof s !== "string") throw Error("需要带双引号的 JSON 字符串字面量");
  return result(s);
};
