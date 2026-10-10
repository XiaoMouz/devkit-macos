import * as he from "he";
import { result } from "../../../../Vendor/common.mjs";
export default (i, o) =>
  result(
    o.operation === "encode"
      ? he.encode(i.text, {
          useNamedReferences: o.named,
          encodeEverything: o.all,
        })
      : he.decode(i.text, { strict: true }),
  );
