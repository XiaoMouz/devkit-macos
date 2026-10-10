import { result } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const bits = BigInt(o.bits),
    mask = (1n << bits) - 1n,
    a = BigInt(i.text),
    b = BigInt(o.right);
  if (a < 0n || a > mask || b < 0n) throw Error("操作数必须在无符号位宽内");
  let v;
  if (o.operation === "shl" || o.operation === "shr") {
    if (b >= bits) throw Error("移位数必须小于位宽");
    v = o.operation === "shl" ? (a << b) & mask : a >> b;
  } else {
    if (b > mask) throw Error("右操作数超过位宽");
    v =
      o.operation === "and"
        ? a & b
        : o.operation === "or"
          ? a | b
          : o.operation === "xor"
            ? a ^ b
            : ~a & mask;
  }
  return result(v.toString(), {
    rows: [
      { label: "二进制", value: v.toString(2).padStart(Number(bits), "0") },
      { label: "十六进制", value: v.toString(16) },
    ],
  });
};
