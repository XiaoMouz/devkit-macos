# 全部工具

按任务选择工具。每个页面都提供操作步骤、可运行示例、参数和边界；英文 ID 可用于侧栏搜索和 CLI。

共 9 类、48 个入口。编码/解码等作为内部操作，JSON 的八种操作共用一个工作台。

## 编码与转换

| 工具 | 用途 |
| --- | --- |
| [Base64](base64.md) | UTF-8 文本编解码；标准 / URL Safe，支持文本导出。 |
| [Data URL](data-url.md) | 图片与 Data URL 互转。 |
| [URL 编解码](url-codec.md) | 组件、完整 URL 和表单模式，明确处理空格与加号。 |

## 结构化数据

| 工具 | 用途 |
| --- | --- |
| [JSON 工作台](json.md) | 格式化、压缩、JSONPath / Pointer、结构对比、Schema 校验与 TypeScript 类型。 |

## 摘要与令牌

| 工具 | 用途 |
| --- | --- |
| [文件校验](file-checksum.md) | 计算文件摘要，并与期望值比较；支持取消。 |
| [哈希摘要](hash.md) | MD5 / SHA 摘要；MD5 和 SHA-1 仅用于兼容与校验。 |
| [HMAC](hmac.md) | SHA-256 / SHA-512 消息认证码；密钥仅在当前会话中使用。 |
| [JWT 工作台](jwt.md) | 解析 Header / Payload；可选 HS256 验签，解析不代表可信。 |
| [PEM 与证书](pem-certificate.md) | 本地 X.509 证书主题、有效期与 SHA-256 指纹。 |

## 标识与测试数据

| 工具 | 用途 |
| --- | --- |
| [Mock 数据](mock-data.md) | 字段模板生成 JSON / CSV；按种子生成可复现测试数据。 |
| [Nano ID](nanoid.md) | 安全随机与无偏采样，可自定义 Unicode 字符集。 |
| [二维码](qr-code.md) | 文本生成 QR，或选择图片识别；PNG 导出。 |
| [随机字符串](random-string.md) | 使用系统安全随机源，自定义字符集与批量生成。 |
| [ULID](ulid.md) | Crockford Base32，48 位毫秒时间戳与 80 位安全随机数。 |
| [UUID](uuid.md) | RFC 9562 UUID v4 / v7，支持批量与大小写。 |

## 文本与匹配

| 工具 | 用途 |
| --- | --- |
| [Markdown](markdown.md) | 本地预览和 HTML 导出；移除脚本与外部资源。 |
| [正则测试](regex.md) | ECMAScript 正则、捕获组和替换预览；独立进程可取消。 |
| [命名与大小写](text-case.md) | camelCase、PascalCase、snake_case 与 kebab-case。 |
| [文本对比](text-diff.md) | 逐行比较，保留两份输入，输出增删行。 |
| [文本行处理](text-lines.md) | 排序、去重、去空行、编号和添加前后缀。 |
| [查找替换](text-replace.md) | 普通文本或 ECMAScript 正则，保留原文并预览结果。 |
| [文本统计](text-stats.md) | 区分字素、Unicode 码点、UTF-16 和 UTF-8 字节。 |

## 时间与数值

| 工具 | 用途 |
| --- | --- |
| [Cron](cron.md) | 五字段 Cron，预览后续执行时间，不注册系统任务。 |
| [日期与时区](date-time.md) | 日期时间选择、时区转换、日期加减与时间差。 |
| [进制转换](number-base.md) | 基于大整数精确转换，支持正负数；不隐式套用补码。 |
| [数字格式](number-format.md) | Decimal 十进制舍入与千分位，最多 38 位有效数字。 |
| [时间戳](timestamp.md) | Unix 秒 / 毫秒与日期时间互转，按所选时区显示。 |
| [单位转换](unit-convert.md) | 文件大小、时长和速率，明确 SI 与 IEC。 |

## Web 与网络

| 工具 | 用途 |
| --- | --- |
| [Cookie](cookie.md) | Cookie / Set-Cookie 字段解析，不修改浏览器。 |
| [cURL 转换](curl-convert.md) | 静态解析常用 cURL 参数，输出 fetch；不执行 Shell。 |
| [DNS 查询](dns.md) | 调用系统 dig；A / AAAA / CNAME / MX / TXT / NS，手动执行。 |
| [HTTP 调试](http-client.md) | 显式发送请求；响应、状态与耗时仅留在当前会话。 |
| [HTTP 状态码](http-status.md) | 本地查询 HTTP 状态含义；不发送请求。 |
| [MIME 类型](mime-types.md) | 通过系统 Uniform Type 数据库查询扩展名或 MIME。 |
| [查询参数](query-string.md) | 保留重复键和空值，JSON 键值对与查询字符串互转。 |
| [URL 解析](url-parser.md) | 分解协议、主机、端口、路径、查询与片段。 |
| [WebSocket 调试](websocket.md) | 手动连接、发送与接收，断开后不保存会话。 |

## 前端样式

| 工具 | 用途 |
| --- | --- |
| [颜色转换](color.md) | sRGB HEX / RGB / HSL 与透明度，结果点一下复制。 |
| [颜色对比度](contrast.md) | WCAG 2.2 相对亮度对比值，普通和大号文字分开。 |
| [CSS 单位](css-unit.md) | px / rem / em / vw / vh，基准尺寸明确可调。 |

## 代码与图形

| 工具 | 用途 |
| --- | --- |
| [代码格式化](code-format.md) | Prettier 格式化 JS / TS / HTML / CSS；SQL 可选方言。 |
| [代码压缩](code-minify.md) | 使用解析器压缩 JS / CSS / HTML，不执行输入代码。 |
| [网站图标](favicon.md) | 从图片生成常用 PNG 尺寸与 ICO；原文件不覆盖。 |
| [图片压缩](image-compress.md) | JPEG 有损质量与目标大小；原文件不覆盖。 |
| [图片格式转换](image-convert.md) | 系统编码器转换 PNG / JPEG / HEIC；首帧，默认移除元数据。 |
| [图片信息](image-metadata.md) | 查看尺寸、EXIF 与色彩信息；可导出移除元数据的新 PNG。 |
| [图片尺寸](image-resize.md) | 缩放或居中裁剪到目标尺寸；PNG 导出。 |
| [SVG 工作台](svg.md) | 清理脚本与外部引用，优化 SVG 并在受限视图预览。 |
