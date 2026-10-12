import { tr } from '../../../../Vendor/localization.mjs';
import { result } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  if (!o.search) throw Error(tr("Search text cannot be empty"));
  const s = o.regex
    ? i.text.replace(new RegExp(o.search, o.flags), o.replacement)
    : i.text.split(o.search).join(o.replacement);
  return result(s, { note: tr("The input is unchanged. Copy the result or edit it again.") });
};
