import Ajv from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';
import { safeJSON, result } from '../../../../Vendor/common.mjs';
import { parseJSON, pointer, jsonPreview, statistics, report } from '../../../../Vendor/json-report.mjs';
const types = { object: '对象', array: '数组', string: '字符串', number: '数字', integer: '整数', boolean: '布尔值', null: '空值' };
const value = v => JSON.stringify(v);
function message(e) {
  const p = e.params;
  switch (e.keyword) {
    case 'type': return `应为${String(p.type).split(',').map(t => types[t] || t).join('或')}`;
    case 'required': return `缺少必填字段 ${value(p.missingProperty)}`;
    case 'additionalProperties': case 'unevaluatedProperties': return `不允许字段 ${value(p.additionalProperty ?? p.unevaluatedProperty)}`;
    case 'enum': return `必须是以下值之一：${value(p.allowedValues)}`;
    case 'const': return `必须等于 ${value(p.allowedValue)}`;
    case 'minimum': return `数值必须大于或等于 ${p.limit}`;
    case 'maximum': return `数值必须小于或等于 ${p.limit}`;
    case 'exclusiveMinimum': return `数值必须大于 ${p.limit}`;
    case 'exclusiveMaximum': return `数值必须小于 ${p.limit}`;
    case 'multipleOf': return `数值必须是 ${p.multipleOf} 的整数倍`;
    case 'minLength': return `字符串至少需要 ${p.limit} 个字符`;
    case 'maxLength': return `字符串最多允许 ${p.limit} 个字符`;
    case 'minItems': return `数组至少需要 ${p.limit} 个元素`;
    case 'maxItems': return `数组最多允许 ${p.limit} 个元素`;
    case 'minProperties': return `对象至少需要 ${p.limit} 个字段`;
    case 'maxProperties': return `对象最多允许 ${p.limit} 个字段`;
    case 'uniqueItems': return `数组第 ${p.i + 1} 项与第 ${p.j + 1} 项重复`;
    case 'pattern': return `字符串不符合表达式 ${p.pattern}`;
    case 'format': return `格式不正确，应符合 ${p.format}`;
    case 'anyOf': return '至少需要符合一组候选规则';
    case 'oneOf': return '必须且只能符合一组候选规则';
    case 'not': return '内容命中了禁止的规则';
    case 'if': return '条件分支校验未通过';
    case 'contains': return '数组中符合指定规则的元素数量不满足要求';
    case 'dependentRequired': case 'dependencies': return `字段 ${value(p.property)} 还需要关联字段 ${p.deps}`;
    case 'propertyNames': return `字段名称不符合规则：${value(p.propertyName)}`;
    case 'false schema': return '此位置不允许任何值';
    case 'additionalItems': case 'items': case 'unevaluatedItems': return `数组包含不允许的额外元素${p.limit == null ? '' : `，最多允许 ${p.limit} 项`}`;
    default: return '内容不符合此处的校验规则';
  }
}
export default (i, o) => {
  const data = parseJSON(i.text, 'JSON 数据'), schema = parseJSON(i.secondary, 'JSON Schema');
  const ajv = new Ajv({ allErrors: true, strict: true, verbose: false });
  addFormats(ajv);
  let validate;
  try { validate = ajv.compile(safeJSON(i.secondary)); }
  catch (error) {
    const reason = String(error.message);
    if (/resolve reference|no schema with key/.test(reason)) throw Error('Schema 引用无法解析。请提供本地完整定义；不支持加载远程引用。');
    if (reason.includes('精确范围')) throw error;
    throw Error('Schema 定义无效或包含不受支持的规则。请检查字段类型、关键字及 Draft 2020-12 结构。');
  }
  const valid = validate(safeJSON(i.text));
  const errors = validate.errors || [];
  const selected = errors.slice(0, 500);
  const dataMarks = [], schemaMarks = [];
  const rows = selected.map(e => {
    let path = e.instancePath;
    if (e.keyword === 'required') path = pointer(path, e.params.missingProperty);
    if (e.keyword === 'additionalProperties') path = pointer(path, e.params.additionalProperty);
    if (e.keyword === 'unevaluatedProperties') path = pointer(path, e.params.unevaluatedProperty);
    if (e.keyword === 'propertyNames') path = pointer(path, e.params.propertyName);
    const reason = message(e);
    let schemaPath = e.schemaPath.startsWith('#') ? e.schemaPath.slice(1) : '';
    try { schemaPath = decodeURIComponent(schemaPath); } catch {}
    dataMarks.push({ path, kind: 'error', message: reason });
    schemaMarks.push({ path: schemaPath, kind: 'change', message: reason });
    return { label: path || '/', value: reason + '\n规则：' + (schemaPath || '/') };
  });
  return result(valid ? '校验通过 · Draft 2020-12' : rows.map(r => r.label + ': ' + r.value).join('\n'), {
    rows,
    report: report(valid ? 'success' : 'failure', valid ? 'Schema 校验通过' : `发现 ${errors.length} 个校验问题`,
      valid ? '数据符合所提供的 Schema，字段、类型与约束检查均通过。' : '路径列表说明失败原因；高亮对照同时定位 JSON 数据和 Schema 规则。',
      [{ label: '问题', value: String(errors.length) }, ...statistics(data).slice(0, 3)]),
    html: jsonPreview([{ value: data, title: 'JSON 数据', marks: dataMarks }, { value: schema, title: 'JSON Schema', marks: schemaMarks }], !valid),
    note: (errors.length > selected.length ? `共 ${errors.length} 个问题，显示前 ${selected.length} 个。` : '') + 'Draft 2020-12 · 无远程引用加载；校验不改写输入。',
  });
};
