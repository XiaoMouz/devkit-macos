import { tr } from '../../../../Vendor/localization.mjs';
import {
  safeJSON,
  pretty,
  csvStringify,
  result,
} from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const input = safeJSON(i.text);
  if (!input || typeof input !== "object") throw Error(tr("The template must map fields to types or contain a field list"));
  const entries = Array.isArray(input)
    ? input.map((row) => [row?.name, row?.value])
    : Object.entries(input).sort(([a], [b]) => a < b ? -1 : a > b ? 1 : 0);
  if (!entries.length) throw Error(tr("Add at least one field."));
  if (entries.some(([name]) => typeof name !== "string" || !name.trim())) throw Error(tr("Enter a field name."));
  if (new Set(entries.map(([name]) => name)).size !== entries.length) throw Error(tr("Field names must be unique."));
  const schema = Object.fromEntries(entries);
  if (!Number.isInteger(o.seed) || o.seed < 0 || o.seed > 2147483647) throw Error(tr("Seed must be between 0 and 2,147,483,647."));
  if (o.count < 1 || o.count > 10000) throw Error(tr("Count must be 1–10,000"));
  let seed = o.seed >>> 0;
  const rng = () => {
    seed = (Math.imul(1664525, seed) + 1013904223) >>> 0;
    return seed / 4294967296;
  };
  const types = ["index", "name", "email", "boolean", "integer", "uuid"];
  for (const type of Object.values(schema))
    if (!types.includes(type)) throw Error(tr("Supported types: ") + types.join(", "));
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
    { note: tr("Reproducible test data. Do not use for passwords, tokens, or real identities.") },
  );
};
