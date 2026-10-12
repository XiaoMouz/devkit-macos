// Catalog data is injected by Swift before the bundled parsers are evaluated.
// Replace only source-template placeholders, never braces in user arguments.
export function tr(key, ...arguments_) {
  const template = globalThis.__devkitTranslations?.[key] ?? key;
  return template.replace(/\{([0-9]+)\}/g, (token, index) =>
    Number(index) < arguments_.length ? String(arguments_[Number(index)]) : token);
}
