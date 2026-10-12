import fs from "node:fs";
import path from "node:path";
import { build } from "esbuild";
const base = path.resolve(import.meta.dirname, "../Sources/DevKitCore/Tools");
const ids = fs
  .readdirSync(base)
  .filter((id) => fs.existsSync(path.join(base, id, "Engine.mjs")))
  .sort();
const entry =
  ids
    .map(
      (id, n) =>
        `import m${n} from ${JSON.stringify(path.join(base, id, "Engine.mjs"))};`,
    )
    .join("\n") +
  "\nimport { tr } from './localization.mjs';\nconst engines={" +
  ids.map((id, n) => JSON.stringify(id) + ":m" + n).join(",") +
  '};\nglobalThis.devkitExecute=async(id,input,options)=>{try{if(!engines[id])throw Error(tr("Tool not found"));const result=await engines[id](input,options);const value=JSON.stringify({output:result});if(value.length>24*1024*1024)throw Error(tr("Output exceeds 24 MiB"));return value;}catch(e){return JSON.stringify({error:{code:"invalid-input",message:String(e.message||e)}})}};';
await build({
  stdin: { contents: entry, resolveDir: import.meta.dirname, loader: "js" },
  nodePaths: [path.join(import.meta.dirname, "node_modules")],
  bundle: true,
  platform: "browser",
  format: "iife",
  target: "safari18",
  minify: true,
  legalComments: "eof",
  outfile: path.resolve(
    import.meta.dirname,
    "../Sources/DevKitCore/Resources/engines.js",
  ),
  define: { "process.env.NODE_ENV": '"production"' },
});
await build({
  entryPoints: [path.join(import.meta.dirname, "syntax.mjs")],
  bundle: true, platform: "browser", format: "iife", target: "safari18",
  minify: true, legalComments: "eof",
  outfile: path.resolve(import.meta.dirname, "../Sources/DevKitCore/Resources/syntax.js"),
});
// Include full dependency licenses, not only minifier-preserved banners.
let notices =
  "# Third-party notices\n\nDependencies are bundled locally; the app never loads scripts from a CDN.\n";
const lock = JSON.parse(
  fs.readFileSync(path.join(import.meta.dirname, "package-lock.json")),
);
for (const entry of Object.keys(lock.packages)
  .filter((p) => p.startsWith("node_modules/"))
  .sort()) {
  const dir = path.join(import.meta.dirname, entry);
  if (!fs.existsSync(path.join(dir, "package.json"))) continue;
  const pkg = JSON.parse(fs.readFileSync(path.join(dir, "package.json"))),
    name = pkg.name;
  const license = fs
    .readdirSync(dir)
    .find((n) => /^licen[sc]e(?:[.-]|$)/i.test(n));
  let licenseText;
  if (license) licenseText = fs.readFileSync(path.join(dir, license), "utf8");
  else if (name === "boolbase") licenseText = fs.readFileSync(path.join(import.meta.dirname, "licenses/boolbase-LICENSE"), "utf8");
  else if (name.startsWith("@esbuild/")) licenseText = fs.readFileSync(path.join(import.meta.dirname, "node_modules/esbuild/LICENSE.md"), "utf8");
  else if (name === "railroad-diagrams") licenseText = fs.readFileSync(path.join(dir, "README.md"), "utf8").split("License\n").pop();
  else throw Error("Missing license: " + name);
  notices += `\n## ${name} ${pkg.version} (${pkg.license})\n\n` + licenseText + "\n";
}
fs.writeFileSync(
  path.join(
    import.meta.dirname,
    "../Sources/DevKitCore/Resources/ThirdPartyNotices.txt",
  ),
  notices,
);
