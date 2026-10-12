import { tr } from '../../../../Vendor/localization.mjs';
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
        if (next === undefined) throw Error(tr("Incomplete escape sequence"));
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
      if (next === undefined) throw Error(tr("Incomplete escape sequence"));
      token += next;
      active = true;
    } else if (/\s/.test(c)) {
      if (active) {
        tokens.push(token);
        token = "";
        active = false;
      }
    } else if (/[|;<>`$]/.test(c)) {
      throw Error(tr("Shell pipes, redirection, and variable expansion are unsupported"));
    } else {
      token += c;
      active = true;
    }
  }
  if (quote) throw Error(tr("Unclosed quote"));
  if (active) tokens.push(token);
  if (tokens.shift() !== "curl") throw Error(tr("The command must start with curl"));
  let url = "",
    method = "GET",
    body,
    headers = {};
  const take = () => {
    if (!tokens.length) throw Error(tr("Missing option value"));
    return tokens.shift();
  };
  while (tokens.length) {
    const t = tokens.shift();
    if (t === "-X" || t === "--request") method = take();
    else if (t === "-H" || t === "--header") {
      const h = take(),
        n = h.indexOf(":");
      if (n < 1) throw Error(tr("Header is missing a colon"));
      headers[h.slice(0, n)] = h.slice(n + 1).trim();
    } else if (["-d", "--data", "--data-raw", "--data-binary"].includes(t)) {
      body = take();
      if (body.startsWith("@")) throw Error(tr("@file input is not read. Provide the request body directly."));
      if (method === "GET") method = "POST";
    } else if (t === "--url") url = take();
    else if (t === "--compressed" || t === "-s" || t === "--silent") {
    } else if (t.startsWith("-")) throw Error(tr("Unsupported cURL option: ") + t);
    else if (!url) url = t;
    else throw Error(tr("Only one URL is supported"));
  }
  if (!/^https?:\/\//i.test(url)) throw Error(tr("Only HTTP and HTTPS URLs are supported"));
  const request = { method, headers, ...(body === undefined ? {} : { body }) };
  return result(
    o.format === "fetch"
      ? "const response = await fetch(" +
          JSON.stringify(url) +
          ", " +
          pretty(request) +
          ");\nconst data = await response.text();"
      : pretty({ url, ...request }),
    { note: tr("Supports -X, -H, -d, --data-raw, --data-binary, and --url. The command is not executed.") },
  );
};
