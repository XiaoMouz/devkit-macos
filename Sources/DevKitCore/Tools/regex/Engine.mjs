import { result, pretty } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const r = new RegExp(o.pattern, o.flags);
  if (o.operation === "replace")
    return result(i.text.replace(r, o.replacement));
  const rows = [];
  if (!r.global && !r.sticky) {
    const m = r.exec(i.text);
    if (m)
      rows.push({
        index: m.index,
        match: m[0],
        groups: m.slice(1),
        named: m.groups,
      });
  } else {
    let m;
    while ((m = r.exec(i.text))) {
      rows.push({
        index: m.index,
        match: m[0],
        groups: m.slice(1),
        named: m.groups,
      });
      if (rows.length >= 10000) throw Error("匹配超过 10000 项");
      if (m[0] === "") {
        if (r.unicode && i.text.codePointAt(r.lastIndex) > 0xffff)
          r.lastIndex += 2;
        else r.lastIndex++;
      }
    }
  }
  return result(pretty(rows), {
    rows: rows.map((r, n) => ({
      label: "#" + (n + 1) + " · UTF-16 " + r.index,
      value: r.match,
    })),
    note: rows.length + " 个匹配；位置以 UTF-16 单元计数",
  });
};
