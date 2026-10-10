import { pretty, result } from "../../../../Vendor/common.mjs";
export default (i, o) => {
  const tokens = [];
  let token = "",
    quote = null,
    active = false;
  for (let n = 0; n < i.text.length; n++) {
    const c = i.text[n];
    if (quote) {
      if (c === quote) quote = null;
      else if (c === "\\" && quote === '"') {
        const next = i.text[++n];
        if (next === undefined) throw Error("转义不完整");
        token += next;
      } else token += c;
      active = true;
    } else if (c === '"' || c === "'") {
      quote = c;
      active = true;
    } else if (c === "\\") {
      if (i.text[n + 1] === "\n") {
        n++;
        continue;
      }
      const next = i.text[++n];
      if (next === undefined) throw Error("转义不完整");
      token += next;
      active = true;
    } else if (/\s/.test(c)) {
      if (active) {
        tokens.push(token);
        token = "";
        active = false;
      }
    } else if (/[|;<>`$]/.test(c)) {
      throw Error("不支持 Shell 管道、重定向或变量展开");
    } else {
      token += c;
      active = true;
    }
  }
  if (quote) throw Error("引号未闭合");
  if (active) tokens.push(token);
  if (tokens.shift() !== "curl") throw Error("命令必须以 curl 开头");
  let url = "",
    method = "GET",
    body,
    headers = {};
  const take = () => {
    if (!tokens.length) throw Error("参数缺少值");
    return tokens.shift();
  };
  while (tokens.length) {
    const t = tokens.shift();
    if (t === "-X" || t === "--request") method = take();
    else if (t === "-H" || t === "--header") {
      const h = take(),
        n = h.indexOf(":");
      if (n < 1) throw Error("请求头缺少冒号");
      headers[h.slice(0, n)] = h.slice(n + 1).trim();
    } else if (["-d", "--data", "--data-raw", "--data-binary"].includes(t)) {
      body = take();
      if (body.startsWith("@")) throw Error("不读取 @文件，请直接提供请求体");
      if (method === "GET") method = "POST";
    } else if (t === "--url") url = take();
    else if (t === "--compressed" || t === "-s" || t === "--silent") {
    } else if (t.startsWith("-")) throw Error("未支持的 cURL 参数：" + t);
    else if (!url) url = t;
    else throw Error("只支持一个 URL");
  }
  if (!/^https?:\/\//i.test(url)) throw Error("只支持 HTTP / HTTPS URL");
  const request = { method, headers, ...(body === undefined ? {} : { body }) };
  return result(
    o.format === "fetch"
      ? "const response = await fetch(" +
          JSON.stringify(url) +
          ", " +
          pretty(request) +
          ");\nconst data = await response.text();"
      : pretty({ url, ...request }),
    { note: "支持 -X、-H、-d、--data-raw、--data-binary、--url；不执行命令。" },
  );
};
