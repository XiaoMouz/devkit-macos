import { stringifyLossless as str, result } from '../../../../Vendor/common.mjs';
import { parseJSON, pointer, jsonPreview, report } from '../../../../Vendor/json-report.mjs';
export default (i, o) => {
  const rows = [], left = [], right = [];
  let added = 0, removed = 0, changed = 0;
  const walk = (a, b, p, d) => {
    if (d > 100) throw Error('嵌套过深');
    if (str(a) === str(b)) return;
    if (a && b && typeof a === 'object' && typeof b === 'object' && !a.isLosslessNumber && !b.isLosslessNumber && Array.isArray(a) === Array.isArray(b)) {
      for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) {
        const path = pointer(p, k);
        if (!Object.hasOwn(a, k)) {
          added++;
          rows.push({ label: '+ ' + path, value: '新增：' + str(b[k]) });
          right.push({ path, kind: 'add', message: '新增内容' });
        } else if (!Object.hasOwn(b, k)) {
          removed++;
          rows.push({ label: '− ' + path, value: '删除：' + str(a[k]) });
          left.push({ path, kind: 'remove', message: '删除内容' });
        } else walk(a[k], b[k], path, d + 1);
        if (rows.length > 10000) throw Error('差异超过 10000 处');
      }
    } else {
      changed++;
      rows.push({ label: '~ ' + (p || '/'), value: str(a) + ' → ' + str(b) });
      left.push({ path: p, kind: 'change', message: '修改前' });
      right.push({ path: p, kind: 'change', message: '修改后' });
    }
  };
  const a = parseJSON(i.text, '原始 JSON'), b = parseJSON(i.secondary, '对比 JSON');
  walk(a, b, '', 0);
  return result(rows.length ? rows.map(r => r.label + ' ' + r.value).join('\n') : '两个 JSON 结构相同', {
    rows,
    report: report(rows.length ? 'difference' : 'success', rows.length ? `发现 ${rows.length} 处差异` : '两个 JSON 结构一致',
      rows.length ? '按 JSON 路径定位变化，切换高亮对照查看两侧内容。' : '字段顺序和排版不影响比较；所有字段、类型与值均一致。',
      [{ label: '新增', value: String(added) }, { label: '删除', value: String(removed) }, { label: '修改', value: String(changed) }]),
    html: jsonPreview([{ value: a, title: '原始 JSON', marks: left }, { value: b, title: '对比 JSON', marks: right }], true),
  });
};
