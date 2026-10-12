import { tr } from '../../../../Vendor/localization.mjs';
import { result, pretty } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  let r;
  try { r = new RegExp(o.pattern, o.flags); }
  catch (error) { throw Error(tr("Invalid regex or flags. Flags cannot repeat, and u and v cannot be combined.\n") + error.message); }
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
      if (rows.length > 10000) throw Error(tr("More than 10,000 matches"));
      if (m[0] === "") {
        if ((r.unicode || r.unicodeSets) && i.text.codePointAt(r.lastIndex) > 0xffff)
          r.lastIndex += 2;
        else r.lastIndex++;
      }
    }
  }
  return result(pretty(rows), {
    rows: rows.map((r, n) => ({
      label: "#" + (n + 1) + " · UTF-16 " + r.index,
      value: r.match + r.groups.map((value, index) => `\n$${index + 1}: ${value ?? tr("(Unmatched)")}`).join("") + (r.named ? "\n" + pretty(r.named) : ""),
    })),
    note: tr("Matches: {0}; positions use UTF-16 units", rows.length),
  });
};
