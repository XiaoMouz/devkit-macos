import { parseLossless, stringifyLossless, escapeHTML as esc } from './common.mjs';

export const pointer = (path, key) => path + '/' + String(key).replace(/~/g, '~0').replace(/\//g, '~1');
const container = v => v !== null && typeof v === 'object' && !v.isLosslessNumber;
export function parseJSON(text, label = 'JSON') {
  try { return parseLossless(text); }
  catch (error) { throw Error(jsonError(text, error, label).message); }
}
export function jsonError(text, error, label = 'JSON') {
  const match = String(error.message).match(/(?:position|char(?:acter)?)\s+(\d+)/i);
  const offset = match ? Math.min(Number(match[1]), text.length) : text.length;
  const before = text.slice(0, offset).split('\n');
  const line = before.length, column = before.at(-1).length + 1;
  return { line, column, message: `${label} 格式无效：第 ${line} 行，第 ${column} 列附近。请检查引号、逗号、括号和数值格式。` };
}
export function statistics(value) {
  let objects = 0, arrays = 0, items = 0, leaves = 0, maxDepth = 0;
  const walk = (v, depth) => {
    if (depth > 100) throw Error('JSON 嵌套超过 100 层');
    maxDepth = Math.max(maxDepth, depth);
    if (!container(v)) { leaves++; return; }
    if (Array.isArray(v)) { arrays++; items += v.length; } else objects++;
    for (const child of Object.values(v)) walk(child, depth + 1);
  };
  walk(value, 0);
  return [
    { label: '对象', value: String(objects) }, { label: '数组', value: String(arrays) },
    { label: '数组元素', value: String(items) }, { label: '值', value: String(leaves) },
    { label: '嵌套深度', value: String(maxDepth) },
  ];
}
export const report = (state, title, detail, metrics = []) => ({ state, title, detail, metrics });
const styles = `<style>
body{margin:0;padding:16px!important} .documents{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(320px,100%),1fr));gap:16px;align-items:start}
.document{min-width:0;border:1px solid light-dark(#dde2ea,#39404a);border-radius:10px;overflow:hidden}
h3{font-size:12px;margin:0;padding:12px 14px;background:light-dark(#f3f5f8,#242830);font-weight:600}
.code{font:13px/1.75 ui-monospace,SFMono-Regular,Menlo,monospace;padding:12px;overflow:auto;tab-size:2}
.line,summary{border-radius:4px;overflow-wrap:anywhere;white-space:pre-wrap;min-height:23px;padding:0 5px}
summary{cursor:pointer;list-style-position:outside;margin-left:14px}summary:hover{background-color:light-dark(#e9edf5,#333b47)}
.children{padding-left:20px}.collapsed{display:none}details:not([open])>summary .collapsed{display:inline} .key{color:light-dark(#226db7,#82b7ff)}.string{color:light-dark(#a24928,#eaaf91)}.number{color:light-dark(#287f71,#80c9ba)}.literal{color:light-dark(#8850ad,#c3a5f5)}
.badge{font:11px -apple-system;color:light-dark(#526174,#becbdc);background:light-dark(#edf1f6,#303947);border-radius:4px;padding:2px 6px;margin-left:10px;white-space:nowrap}
.add{background:light-dark(#e0f4e8,#173e2b);border-left:3px solid #36a465}.remove{background:light-dark(#fce5e8,#4d252c);border-left:3px solid #d25b70}
.change{background:light-dark(#fff0ce,#4a3919);border-left:3px solid #c79525}.error{background:light-dark(#fce5e8,#4d252c);border-left:3px solid #d25b70}
.legend{display:flex;gap:12px;flex-wrap:wrap;font-size:12px;color:light-dark(#526174,#becbdc);margin:0 0 12px}.legend span{padding:2px 8px;border-radius:4px}
.notice{font:12px -apple-system;color:light-dark(#667085,#b2bbc9);margin:8px 0}.numbered{display:flex;gap:14px}.ln{color:light-dark(#758195,#9aa8bc);min-width:26px;text-align:right;user-select:none}
</style>`;
function nearest(value, path) {
  if (!path) return '';
  let result = '', current = value;
  for (const token of path.slice(1).split('/')) {
    const key = token.replace(/~1/g, '/').replace(/~0/g, '~');
    if (!container(current) || !Object.hasOwn(current, key)) break;
    current = current[key]; result += '/' + token;
  }
  return result;
}
export function jsonDocument(value, title, marks = []) {
  const marked = new Map(marks.map(m => [nearest(value, m.path), m]));
  let count = 0, truncated = false;
  const walk = (v, path, name, comma, depth, inherited = null) => {
    if (++count > 10000) { truncated = true; return ''; }
    const mark = marked.get(path) || inherited;
    const kind = mark?.kind || '';
    const attr = `class="line ${kind}" title="${esc((path || '/') + (mark?.message ? ' · ' + mark.message : ''))}"`;
    const key = name === null ? '' : `<span class="key">${esc(JSON.stringify(name))}</span>: `;
    if (!container(v)) {
      let text = stringifyLossless(v);
      if (text.length > 4000) { text = text.slice(0, 4000) + '…'; truncated = true; }
      const type = typeof v === 'string' ? 'string' : v?.isLosslessNumber || typeof v === 'number' ? 'number' : 'literal';
      return `<div ${attr}>${key}<span class="${type}">${esc(text)}</span>${comma}</div>`;
    }
    if (depth > 100) throw Error('JSON 嵌套超过 100 层');
    const array = Array.isArray(v), entries = Object.entries(v);
    const open = array ? '[' : '{', close = array ? ']' : '}';
    const badge = `<span class="badge">${array ? '数组大小' : '字段'} ${entries.length}</span>`;
    if (!entries.length) return `<div ${attr}>${key}${open}${close}${comma}${badge}</div>`;
    const children = [];
    for (let index = 0; index < entries.length; index++) {
      if (count >= 10000) { truncated = true; break; }
      const [k, x] = entries[index];
      children.push(walk(x, pointer(path, k), array ? null : k, index < entries.length - 1 ? ',' : '', depth + 1, mark?.path === path ? mark : inherited));
    }
    return `<details open><summary ${attr}>${key}${open}<span class="collapsed"> … ${close}${comma}</span>${badge}</summary><div class="children">${children.join('')}</div><div ${attr}>${close}${comma}</div></details>`;
  };
  const code = walk(value, '', null, '', 0);
  return `<section class="document"><h3>${esc(title)}</h3><div class="code">${code}${truncated ? '<p class="notice">大内容仅显示部分预览；复制或导出可获取完整文本。</p>' : ''}</div></section>`;
}
export function jsonPreview(documents, legend = false) {
  return styles + (legend ? '<div class="legend"><span class="add">＋ 新增</span><span class="remove">− 删除 / 校验失败</span><span class="change">~ 修改 / 对应规则</span></div>' : '')
    + '<p class="notice">点击三角折叠或展开；数组旁显示元素数量。高亮行悬停可查看路径与说明。</p><div class="documents">'
    + documents.map(d => jsonDocument(d.value, d.title, d.marks)).join('') + '</div>';
}
export function sourcePreview(text, line, title = 'JSON 输入') {
  return styles + `<section class="document"><h3>${esc(title)}</h3><div class="code">`
    + text.split('\n').slice(0, 10000).map((s, i) => `<div class="line numbered ${i + 1 === line ? 'error' : ''}"><span class="ln">${i + 1}</span><span>${esc(s.slice(0, 4000)) || ' '}</span></div>`).join('') + '</div></section>';
}
