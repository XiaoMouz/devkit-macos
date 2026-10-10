import { CronExpressionParser } from "cron-parser";
import { result } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  if (i.text.trim().split(/\s+/).length !== 5)
    throw Error("此工具只支持五字段 Cron：分 时 日 月 周");
  if (o.count < 1 || o.count > 100) throw Error("次数必须为 1–100");
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
      "按 " +
      o.timezone +
      " 计算；结果显示 UTC ISO 8601。日和周按 cron-parser 的 Unix 语义匹配。",
  });
};
