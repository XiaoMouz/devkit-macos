import {
  safeJSON,
  pretty,
  csvStringify,
  result,
} from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const schema = safeJSON(i.text);
  if (!schema || Array.isArray(schema) || typeof schema !== "object")
    throw Error("模板必须为字段到类型的对象");
  if (o.count < 1 || o.count > 10000) throw Error("数量必须为 1–10000");
  let seed = o.seed >>> 0;
  const rng = () => {
    seed = (Math.imul(1664525, seed) + 1013904223) >>> 0;
    return seed / 4294967296;
  };
  const types = ["index", "name", "email", "boolean", "integer", "uuid"];
  for (const type of Object.values(schema))
    if (!types.includes(type)) throw Error("支持类型：" + types.join(", "));
  const names = ["Ada", "Lin", "Alex", "Kai", "Sam", "Mia"];
  const rows = Array.from({ length: o.count }, (_, n) =>
    Object.fromEntries(
      Object.entries(schema).map(([key, type]) => [
        key,
        type === "index"
          ? n + 1
          : type === "name"
            ? names[Math.floor(rng() * names.length)]
            : type === "email"
              ? "user" + (n + 1) + "@example.test"
              : type === "boolean"
                ? rng() < 0.5
                : type === "integer"
                  ? Math.floor(rng() * 10000)
                  : "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(
                      /[xy]/g,
                      (c) => {
                        const r = Math.floor(rng() * 16);
                        return (c === "x" ? r : (r & 3) | 8).toString(16);
                      },
                    ),
      ]),
    ),
  );
  return result(
    o.format === "json"
      ? pretty(rows)
      : csvStringify([Object.keys(schema), ...rows.map(Object.values)]),
    { note: "可复现测试数据；不用于密码、令牌或真实身份。" },
  );
};
