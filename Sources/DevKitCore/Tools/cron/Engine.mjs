import { tr } from '../../../../Vendor/localization.mjs';
import { CronExpressionParser } from "cron-parser";
import { result } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  if (i.text.trim().split(/\s+/).length !== 5)
    throw Error(tr("This tool only supports five-field Cron: minute hour day month weekday"));
  if (o.count < 1 || o.count > 100) throw Error(tr("Count must be 1–100"));
  const expression = CronExpressionParser.parse(i.text, {
    tz: o.timezone,
    currentDate: o.start || new Date(),
  });
  const values = Array.from({ length: o.count }, () =>
    expression.next().toDate().toISOString(),
  );
  return result(values.join("\n"), {
    rows: values.map((v, n) => ({ label: String(n + 1), value: v })),
    note:
      tr("Calculated in {0}; results use UTC ISO 8601. Day and weekday follow cron-parser’s Unix semantics.", o.timezone),
  });
};
