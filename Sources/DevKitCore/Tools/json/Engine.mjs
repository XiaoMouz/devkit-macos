import { stringifyLossless, result } from '../../../../Vendor/common.mjs';
import { parseJSON, jsonPreview, sourcePreview, statistics, report, pointer } from '../../../../Vendor/json-report.mjs';
export default (i, o) => {
  let value;
  try { value = parseJSON(i.text); }
  catch (error) {
    if (o.operation !== 'validate') throw error;
    // parseJSON has already localized the location; retain it in the report.
    const position = error.message.match(/第 (\d+) 行，第 (\d+) 列/);
    const line = Number(position?.[1] || 1), column = Number(position?.[2] || 1);
    return result(error.message, {
      rows: [{ label: `第 ${line} 行 · 第 ${column} 列`, value: error.message }],
      report: report('failure', 'JSON 校验未通过', '发现语法问题，请根据位置检查输入。', [{ label: '问题', value: '1' }]),
      html: sourcePreview(i.text, line),
    });
  }
  if (o.operation === 'validate') return result('JSON 有效', {
    report: report('success', 'JSON 校验通过', '语法完整，可用于格式化、路径查询和结构对比。', statistics(value)),
    html: jsonPreview([{ value, title: '已校验的 JSON' }]),
  });
  if (o.operation === 'tree') {
    const rows = [];
    const walk = (v, p, d) => {
      if (d > 100) throw Error('树深度超过 100');
      if (v !== null && typeof v === 'object' && !v.isLosslessNumber) {
        if (Array.isArray(v)) rows.push({ label: p || '/', value: `数组大小 ${v.length}` });
        for (const [k, x] of Object.entries(v)) walk(x, pointer(p, k), d + 1);
      } else rows.push({ label: p || '/', value: stringifyLossless(v) });
      if (rows.length > 10000) throw Error('树节点超过 10000');
    };
    walk(value, '', 0);
    return result(rows.map(r => r.label + ' = ' + r.value).join('\n'), { rows });
  }
  return result(stringifyLossless(value, null, o.operation === 'minify' ? undefined : 2),
    o.operation === 'minify' ? {} : { html: jsonPreview([{ value, title: '格式化 JSON' }]) });
};
