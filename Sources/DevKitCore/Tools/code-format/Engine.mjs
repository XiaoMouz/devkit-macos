import * as prettier from "prettier/standalone";
import * as babel from "prettier/plugins/babel";
import * as estree from "prettier/plugins/estree";
import * as ts from "prettier/plugins/typescript";
import * as html from "prettier/plugins/html";
import * as postcss from "prettier/plugins/postcss";
import { format } from "sql-formatter";
import { result } from "../../../../Vendor/common.mjs";
export default async (i, o) =>
  result(
    o.language === "sql"
      ? format(i.text, { language: o.dialect })
      : await prettier.format(i.text, {
          parser: {
            javascript: "babel",
            typescript: "typescript",
            html: "html",
            css: "css",
          }[o.language],
          plugins: [babel, estree, ts, html, postcss],
          tabWidth: o.indent,
        }),
  );
