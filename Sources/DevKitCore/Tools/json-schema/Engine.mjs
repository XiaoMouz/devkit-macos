import { tr } from '../../../../Vendor/localization.mjs';
import Ajv from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';
import { safeJSON, result } from '../../../../Vendor/common.mjs';
import { parseJSON, pointer, jsonPreview, statistics, report } from '../../../../Vendor/json-report.mjs';
const types = { object: tr("Object"), array: tr("Array"), string: tr("String"), number: tr("Number"), integer: tr("Integer"), boolean: tr("Boolean"), null: tr("Null") };
const value = v => JSON.stringify(v);
function message(e) {
  const p = e.params;
  switch (e.keyword) {
    case 'type': return tr("Expected {0}", String(p.type).split(',').map(t => types[t] || t).join(tr(" or ")));
    case 'required': return tr("Missing required field {0}", value(p.missingProperty));
    case 'additionalProperties': case 'unevaluatedProperties': return tr("Field {0} is not allowed", value(p.additionalProperty ?? p.unevaluatedProperty));
    case 'enum': return tr("Must be one of: {0}", value(p.allowedValues));
    case 'const': return tr("Must equal {0}", value(p.allowedValue));
    case 'minimum': return tr("Number must be greater than or equal to {0}", p.limit);
    case 'maximum': return tr("Number must be less than or equal to {0}", p.limit);
    case 'exclusiveMinimum': return tr("Number must be greater than {0}", p.limit);
    case 'exclusiveMaximum': return tr("Number must be less than {0}", p.limit);
    case 'multipleOf': return tr("Number must be an integer multiple of {0}", p.multipleOf);
    case 'minLength': return tr("Minimum string length: {0}", p.limit);
    case 'maxLength': return tr("Maximum string length: {0}", p.limit);
    case 'minItems': return tr("Minimum array items: {0}", p.limit);
    case 'maxItems': return tr("Maximum array items: {0}", p.limit);
    case 'minProperties': return tr("Minimum object fields: {0}", p.limit);
    case 'maxProperties': return tr("Maximum object fields: {0}", p.limit);
    case 'uniqueItems': return tr("Array item {0} duplicates item {1}", p.i + 1, p.j + 1);
    case 'pattern': return tr("String does not match expression {0}", p.pattern);
    case 'format': return tr("Invalid format; expected {0}", p.format);
    case 'anyOf': return tr("Must match at least one candidate rule set");
    case 'oneOf': return tr("Must match exactly one candidate rule set");
    case 'not': return tr("Content matches a forbidden rule");
    case 'if': return tr("Conditional branch validation failed");
    case 'contains': return tr("The number of array items matching the rule does not meet the requirement");
    case 'dependentRequired': case 'dependencies': return tr("Field {0} also requires related fields {1}", value(p.property), p.deps);
    case 'propertyNames': return tr("Field name does not match the rule: {0}", value(p.propertyName));
    case 'false schema': return tr("No value is allowed here");
    case 'additionalItems': case 'items': case 'unevaluatedItems': return tr("Array contains forbidden extra items{0}", p.limit == null ? '' : tr("; maximum items: {0}", p.limit));
    default: return tr("Content does not match the validation rules here");
  }
}
export default (i, o) => {
  const data = parseJSON(i.text, tr("JSON Data")), schema = parseJSON(i.secondary, 'JSON Schema');
  const ajv = new Ajv({ allErrors: true, strict: true, verbose: false });
  addFormats(ajv);
  let validate;
  try { validate = ajv.compile(safeJSON(i.secondary)); }
  catch (error) {
    const reason = String(error.message);
    if (/resolve reference|no schema with key/.test(reason)) throw Error(tr("Schema reference cannot be resolved. Provide a complete local definition; remote references are unsupported."));
    if (error.code === 'unsafe-number') throw error;
    throw Error(tr("Invalid Schema definition or unsupported rules. Check field types, keywords, and the Draft 2020-12 structure."));
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
    return { label: path || '/', value: reason + tr("\nRule: ") + (schemaPath || '/') };
  });
  return result(valid ? tr("Validation Passed · Draft 2020-12") : rows.map(r => r.label + ': ' + r.value).join('\n'), {
    rows,
    report: report(valid ? 'success' : 'failure', valid ? tr("Schema Validation Passed") : tr("Validation Issues Found: {0}", errors.length),
      valid ? tr("Data matches the provided Schema. Field, type, and constraint checks all passed.") : tr("The path list explains failures. The highlighted comparison locates both JSON data and Schema rules."),
      [{ label: tr("Issues"), value: String(errors.length) }, ...statistics(data).slice(0, 3)]),
    html: jsonPreview([{ value: data, title: tr("JSON Data"), marks: dataMarks }, { value: schema, title: 'JSON Schema', marks: schemaMarks }], !valid),
    note: (errors.length > selected.length ? tr("Showing the first {0} of {1} issues.", selected.length, errors.length) : '') + tr("Draft 2020-12 · No remote references are loaded; validation does not modify the input."),
  });
};
