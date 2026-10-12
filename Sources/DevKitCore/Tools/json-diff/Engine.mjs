import { tr } from '../../../../Vendor/localization.mjs';
import { stringifyLossless as str, result } from '../../../../Vendor/common.mjs';
import { parseJSON, pointer, jsonPreview, report } from '../../../../Vendor/json-report.mjs';
export default (i, o) => {
  const rows = [], left = [], right = [];
  let added = 0, removed = 0, changed = 0;
  const walk = (a, b, p, d) => {
    if (d > 100) throw Error(tr("Nesting is too deep"));
    if (str(a) === str(b)) return;
    if (a && b && typeof a === 'object' && typeof b === 'object' && !a.isLosslessNumber && !b.isLosslessNumber && Array.isArray(a) === Array.isArray(b)) {
      for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) {
        const path = pointer(p, k);
        if (!Object.hasOwn(a, k)) {
          added++;
          rows.push({ label: '+ ' + path, value: tr("Added: ") + str(b[k]) });
          right.push({ path, kind: 'add', message: tr("Added Content") });
        } else if (!Object.hasOwn(b, k)) {
          removed++;
          rows.push({ label: '− ' + path, value: tr("Removed: ") + str(a[k]) });
          left.push({ path, kind: 'remove', message: tr("Removed Content") });
        } else walk(a[k], b[k], path, d + 1);
        if (rows.length > 10000) throw Error(tr("More than 10,000 differences"));
      }
    } else {
      changed++;
      rows.push({ label: '~ ' + (p || '/'), value: str(a) + ' → ' + str(b) });
      left.push({ path: p, kind: 'change', message: tr("Before") });
      right.push({ path: p, kind: 'change', message: tr("After") });
    }
  };
  const a = parseJSON(i.text, tr("Original JSON")), b = parseJSON(i.secondary, tr("Comparison JSON"));
  walk(a, b, '', 0);
  return result(rows.length ? rows.map(r => r.label + ' ' + r.value).join('\n') : tr("The JSON structures are identical"), {
    rows,
    report: report(rows.length ? 'difference' : 'success', rows.length ? tr("Differences Found: {0}", rows.length) : tr("The JSON Structures Match"),
      rows.length ? tr("Locate changes by JSON path, or switch to the highlighted comparison to see both sides.") : tr("Field order and formatting do not affect comparison. All fields, types, and values match."),
      [{ label: tr("Added"), value: String(added) }, { label: tr("Removed"), value: String(removed) }, { label: tr("Changed"), value: String(changed) }]),
    html: jsonPreview([{ value: a, title: tr("Original JSON"), marks: left }, { value: b, title: tr("Comparison JSON"), marks: right }], true),
  });
};
