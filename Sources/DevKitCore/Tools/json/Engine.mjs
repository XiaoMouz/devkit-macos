import { tr } from '../../../../Vendor/localization.mjs';
import { stringifyLossless, result } from '../../../../Vendor/common.mjs';
import { parseJSON, jsonPreview, sourcePreview, statistics, report, pointer } from '../../../../Vendor/json-report.mjs';
export default (i, o) => {
  let value;
  try { value = parseJSON(i.text); }
  catch (error) {
    if (o.operation !== 'validate') throw error;
    // Location is structured data, independent of translated error wording.
    const line = error.line || 1, column = error.column || 1;
    return result(error.message, {
      rows: [{ label: tr("Line {0} · Column {1}", line, column), value: error.message }],
      report: report('failure', tr("JSON Validation Failed"), tr("Syntax issues found. Check the input at the indicated location."), [{ label: tr("Issues"), value: '1' }]),
      html: sourcePreview(i.text, line),
    });
  }
  if (o.operation === 'validate') return result(tr("Valid JSON"), {
    report: report('success', tr("JSON Validation Passed"), tr("Valid syntax. Ready for formatting, path queries, and structural comparison."), statistics(value)),
    html: jsonPreview([{ value, title: tr("Validated JSON") }]),
  });
  if (o.operation === 'tree') {
    const rows = [];
    const walk = (v, p, d) => {
      if (d > 100) throw Error(tr("Tree depth exceeds 100"));
      if (v !== null && typeof v === 'object' && !v.isLosslessNumber) {
        if (Array.isArray(v)) rows.push({ label: p || '/', value: tr("Array size {0}", v.length) });
        for (const [k, x] of Object.entries(v)) walk(x, pointer(p, k), d + 1);
      } else rows.push({ label: p || '/', value: stringifyLossless(v) });
      if (rows.length > 10000) throw Error(tr("Tree contains more than 10,000 nodes"));
    };
    walk(value, '', 0);
    return result(rows.map(r => r.label + ' = ' + r.value).join('\n'), { rows });
  }
  return result(stringifyLossless(value, null, o.operation === 'minify' ? undefined : 2),
    o.operation === 'minify' ? {} : { html: jsonPreview([{ value, title: tr("Formatted JSON") }]) });
};
