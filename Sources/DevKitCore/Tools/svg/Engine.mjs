import { tr } from '../../../../Vendor/localization.mjs';
import { optimize } from "svgo/browser";
import { result } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  if (
    /<!DOCTYPE|<!ENTITY|<script|<foreignObject|\bon\w+\s*=|(?:href|src)\s*=|url\s*\(|@import/i.test(
      i.text,
    )
  )
    throw Error(tr("SVG contains scripts, events, entities, or external references. Remove them first."));
  if (!/<svg[\s>]/.test(i.text)) throw Error(tr("An SVG document is required"));
  const value = optimize(i.text, { multipass: false }).data;
  return result(value, {
    html: value,
    note: tr("SVG external references and scripts are rejected. You can export the SVG source."),
  });
};
