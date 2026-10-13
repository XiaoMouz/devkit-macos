// The homepage offers a small browser demo; the complete tool reference describes the app.
export const demoTools = [
  { id: 'json', zh: 'JSON 工作台', en: 'JSON Workspace', group: 0, sample: '{"project":"DevKit","platform":"macOS","tools":["JSON","Base64","UUID"],"features":{"cli":true,"aiSkills":true}}', operations: [['format', '格式化', 'Format'], ['minify', '压缩', 'Minify'], ['validate', '语法校验', 'Validate']] },
  { id: 'base64', zh: 'Base64', en: 'Base64', group: 1, sample: 'Hello, DevKit 👋', operations: [['encode', '编码', 'Encode'], ['decode', '解码', 'Decode']] },
  { id: 'url-codec', zh: 'URL 编解码', en: 'URL Encoder / Decoder', group: 1, sample: 'hello world + DevKit', operations: [['encode', '编码', 'Encode'], ['decode', '解码', 'Decode']] },
  { id: 'timestamp', zh: '时间戳', en: 'Timestamp', group: 0, sample: '1700000000', operations: [['seconds', '秒 → 日期', 'Seconds → date'], ['milliseconds', '毫秒 → 日期', 'Milliseconds → date']] },
  { id: 'uuid', zh: 'UUID', en: 'UUID', group: 0, sample: '', operations: [['v4', '生成 UUID v4', 'Generate UUID v4']] },
  { id: 'text-case', zh: '命名与大小写', en: 'Text Case', group: 2, sample: 'hello world DevKit', operations: [['camel', '小驼峰', 'camelCase'], ['snake', '下划线', 'snake_case'], ['kebab', '短横线', 'kebab-case'], ['upper', '大写', 'UPPERCASE'], ['lower', '小写', 'lowercase']] },
]
export function runDemo(id, input, operation) {
  if (id === 'json') {
    const parsed = JSON.parse(input)
    if (operation === 'validate') return 'valid-json'
    return JSON.stringify(parsed, null, operation === 'minify' ? undefined : 2)
  }
  if (id === 'base64') {
    if (operation === 'decode') return new TextDecoder('utf-8', { fatal: true }).decode(Uint8Array.from(atob(input), c => c.charCodeAt(0)))
    return btoa(Array.from(new TextEncoder().encode(input), byte => String.fromCharCode(byte)).join(''))
  }
  if (id === 'url-codec') return operation === 'decode' ? decodeURIComponent(input) : encodeURIComponent(input)
  if (id === 'timestamp') {
    if (!/^-?\d+$/.test(input.trim())) throw new Error('Invalid timestamp')
    const value = Number(input) * (operation === 'seconds' ? 1000 : 1)
    const date = new Date(value)
    if (!Number.isSafeInteger(value) || !Number.isFinite(date.getTime())) throw new Error('Invalid timestamp')
    return `${date.toISOString()}\n\nUnix (s)   ${value / 1000}\nUnix (ms)  ${value}\nUTC`
  }
  if (id === 'uuid') return Array.from({ length: 3 }, () => crypto.randomUUID()).join('\n\n')
  if (id === 'text-case') {
    const words = input.replace(/([a-z\d])([A-Z])/g, '$1 $2').split(/[\s_\-.,;:/]+/).filter(Boolean).map(word => word.toLowerCase())
    if (operation === 'upper') return input.toUpperCase()
    if (operation === 'lower') return input.toLowerCase()
    if (operation === 'camel') return words.map((word, index) => index ? word[0].toUpperCase() + word.slice(1) : word).join('')
    return words.join(operation === 'snake' ? '_' : '-')
  }
  throw new Error('Unknown demo')
}
export function jsonTokens(text) {
  return (text.match(/"(?:\\.|[^"\\])*"\s*:|"(?:\\.|[^"\\])*"|\b(?:true|false|null)\b|-?\d+(?:\.\d+)?(?:e[+-]?\d+)?|[^"\w\d-]+|./gi) || []).map(value => ({
    value,
    type: /^".*:\s*$/.test(value) ? 'key' : value.startsWith('"') ? 'string' : /^(true|false|null)$/.test(value) ? 'literal' : /^-?\d/.test(value) ? 'number' : 'plain',
  }))
}
