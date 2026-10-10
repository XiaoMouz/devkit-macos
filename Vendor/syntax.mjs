import hljs from 'highlight.js/lib/core';
import json from 'highlight.js/lib/languages/json';
import javascript from 'highlight.js/lib/languages/javascript';
import typescript from 'highlight.js/lib/languages/typescript';
import xml from 'highlight.js/lib/languages/xml';
import css from 'highlight.js/lib/languages/css';
import sql from 'highlight.js/lib/languages/sql';
import markdown from 'highlight.js/lib/languages/markdown';
import yaml from 'highlight.js/lib/languages/yaml';
import ini from 'highlight.js/lib/languages/ini';
import bash from 'highlight.js/lib/languages/bash';
import swift from 'highlight.js/lib/languages/swift';
import python from 'highlight.js/lib/languages/python';
import java from 'highlight.js/lib/languages/java';
import cpp from 'highlight.js/lib/languages/cpp';
import csharp from 'highlight.js/lib/languages/csharp';
import go from 'highlight.js/lib/languages/go';
import rust from 'highlight.js/lib/languages/rust';
import http from 'highlight.js/lib/languages/http';
import diff from 'highlight.js/lib/languages/diff';
for (const [name, grammar] of Object.entries({json, javascript, typescript, xml, css, sql, markdown, yaml, ini, bash, swift, python, java, cpp, csharp, go, rust, http, diff})) {
  hljs.registerLanguage(name, grammar);
}
hljs.safeMode();
const entities = {amp:'&', lt:'<', gt:'>', quot:'"', apos:"'"};
const decode = value => value.replace(/&(#x[\da-f]+|#\d+|amp|lt|gt|quot|apos);/gi, (_, key) => {
  if (key[0] !== '#') return entities[key];
  return String.fromCodePoint(key[1].toLowerCase() === 'x' ? parseInt(key.slice(2),16) : parseInt(key.slice(1),10));
});
function kind(classes) {
  const scope = classes.replace(/hljs-/g, '');
  if (/comment|quote/.test(scope)) return 'comment';
  if (/attr|property|selector-attr/.test(scope)) return 'key';
  if (/string|regexp|char|template-tag/.test(scope)) return 'string';
  if (/number/.test(scope)) return 'number';
  if (/keyword|literal|meta/.test(scope)) return 'keyword';
  if (/title|type|built_in|name|selector|section/.test(scope)) return 'type';
  if (/addition/.test(scope)) return 'addition';
  if (/deletion/.test(scope)) return 'deletion';
  if (/link|symbol|bullet/.test(scope)) return 'key';
  return null;
}
// Only bundled grammar code runs. The source is passed as a string, never evaluated.
globalThis.devkitHighlight = (text, language) => {
  if (text.length > 200000 || !hljs.getLanguage(language)) return '[]';
  const html = hljs.highlight(text, {language, ignoreIllegals:true}).value;
  const stack = [], tokens = [];
  let restored = '';
  for (const match of html.matchAll(/<span class="([^"]+)">|<\/span>|([^<]+)/g)) {
    if (match[1] !== undefined) { stack.push(kind(match[1])); continue; }
    if (match[0] === '</span>') { stack.pop(); continue; }
    const value = decode(match[2]);
    const style = [...stack].reverse().find(Boolean);
    const start = restored.length;
    restored += value;
    if (!style || !value.length) continue;
    const last = tokens[tokens.length - 1];
    if (last && last.kind === style && last.location + last.length === start) last.length += value.length;
    else tokens.push({location:start, length:value.length, kind:style});
  }
  // A grammar must never change text, including entity-like input and UTF-16 offsets.
  return JSON.stringify(restored === text && tokens.length <= 30000 ? tokens : []);
};
