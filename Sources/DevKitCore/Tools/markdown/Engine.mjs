import { tr } from '../../../../Vendor/localization.mjs';
import { marked } from "marked";
import sanitize from "sanitize-html";
import { result } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const html = sanitize(marked.parse(i.text), {
    allowedTags: sanitize.defaults.allowedTags.filter((t) => t !== "a"),
    allowedAttributes: {},
    allowedSchemes: [],
  });
  return result(html, {
    html,
    note: tr("The preview does not load external resources. Raw HTML is sanitized using an allowlist."),
  });
};
