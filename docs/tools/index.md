# 工具目录

选择工具查看操作步骤、示例和参数。

## 编码与转换

| 工具 | 用途 |
| --- | --- |
| [Base64](base64.md) | UTF-8 文本的 Base64 编码与解码，支持标准和 URL 安全模式。 |
| [Data URL](data-url.md) | 图片与 Data URL 互转。 |
| [URL 编解码](url-codec.md) | URL 参数、完整 URL 和表单内容的编码与解码。 |

## 结构化数据

| 工具 | 用途 |
| --- | --- |
| [JSON 工作台](json.md) | 格式化、压缩、路径查询、结构对比、Schema 校验与 TypeScript 类型生成。 |

## 摘要与令牌

| 工具 | 用途 |
| --- | --- |
| [文件校验](file-checksum.md) | 计算文件摘要，并与预期值比较。 |
| [哈希摘要](hash.md) | 计算 MD5、SHA-1、SHA-256 和 SHA-512 摘要。 |
| [HMAC](hmac.md) | 使用密钥计算 SHA-256 或 SHA-512 消息认证码。 |
| [JWT 工作台](jwt.md) | 解析 JWT 头部与载荷，并支持 HS256 验签。 |
| [PEM 与证书](pem-certificate.md) | 查看 X.509 证书的主体、有效期和 SHA-256 指纹。 |

## 标识与测试数据

| 工具 | 用途 |
| --- | --- |
| [Mock 数据](mock-data.md) | 根据字段模板生成 JSON 或 CSV 测试数据。 |
| [Nano ID](nanoid.md) | 按长度和字符集生成 Nano ID。 |
| [二维码](qr-code.md) | 生成二维码 PNG，或从图片中识别二维码。 |
| [随机字符串](random-string.md) | 按字符集、长度和数量生成随机字符串。 |
| [ULID](ulid.md) | 生成 ULID，或解析其中的时间。 |
| [UUID](uuid.md) | 生成 UUID v4 或 v7，支持批量、大小写与连字符设置。 |

## 文本与匹配

| 工具 | 用途 |
| --- | --- |
| [Markdown](markdown.md) | 预览 Markdown，导出 HTML。 |
| [正则测试](regex.md) | 测试 ECMAScript 正则表达式，查看捕获组和替换结果。 |
| [命名与大小写](text-case.md) | 转换为小驼峰、大驼峰、下划线、短横线命名，或统一大写、小写。 |
| [文本对比](text-diff.md) | 逐行比较两份文本，查看增加与删除的内容。 |
| [文本行处理](text-lines.md) | 排序、去重、去空行、编号和添加前后缀。 |
| [查找替换](text-replace.md) | 使用普通文本或正则表达式查找替换。 |
| [文本统计](text-stats.md) | 统计字符、Unicode 码点、UTF-16、UTF-8 字节与行数。 |

## 时间与数值

| 工具 | 用途 |
| --- | --- |
| [Cron](cron.md) | 根据五字段 Cron 表达式查询后续执行时间。 |
| [日期与时区](date-time.md) | 时区转换、日期加减与时间差计算。 |
| [进制转换](number-base.md) | 整数进制转换，支持大整数和负数。 |
| [数字格式](number-format.md) | 设置小数位、舍入方式和千分位。 |
| [时间戳](timestamp.md) | Unix 秒、毫秒与日期时间互转。 |
| [单位转换](unit-convert.md) | 文件大小、时长和速率换算。 |

## Web 与网络

| 工具 | 用途 |
| --- | --- |
| [Cookie](cookie.md) | 解析 Cookie 和 Set-Cookie 字段。 |
| [cURL 转换](curl-convert.md) | 将 cURL 命令转换为 fetch 代码或 JSON。 |
| [DNS 查询](dns.md) | 查询 A、AAAA、CNAME、MX、TXT 等 DNS 记录。 |
| [HTTP 调试](http-client.md) | 发送 HTTP 请求，查看响应正文、状态码、请求耗时与响应头。 |
| [HTTP 状态码](http-status.md) | 查询 HTTP 状态码的名称和含义。 |
| [MIME 类型](mime-types.md) | 查询扩展名与 MIME 类型。 |
| [查询参数](query-string.md) | 解析、生成和排序查询参数，保留重复键与空值。 |
| [URL 解析](url-parser.md) | 查看 URL 的协议、主机、端口、路径、查询和片段。 |
| [WebSocket 调试](websocket.md) | 连接 WebSocket 服务，发送消息并查看收发记录。 |

## 前端样式

| 工具 | 用途 |
| --- | --- |
| [颜色转换](color.md) | 转换 HEX、RGB、HSL 颜色值与透明度。 |
| [颜色对比度](contrast.md) | 计算前景色与背景色的对比度，查看 WCAG AA / AAA 结果。 |
| [CSS 单位](css-unit.md) | 在 px、rem、em、vw 和 vh 之间换算。 |

## 代码与图形

| 工具 | 用途 |
| --- | --- |
| [代码格式化](code-format.md) | 格式化 JavaScript、TypeScript、HTML、CSS 和 SQL。 |
| [代码压缩](code-minify.md) | 压缩 JavaScript、CSS 和 HTML。 |
| [网站图标](favicon.md) | 从图片生成多尺寸 PNG 和 ICO 网站图标。 |
| [图片压缩](image-compress.md) | 调整 JPEG 质量，或按目标体积压缩图片。 |
| [图片格式转换](image-convert.md) | 在 PNG、JPEG 和 HEIC 格式之间转换。 |
| [图片信息](image-metadata.md) | 查看图片尺寸、EXIF 和色彩信息，或移除元数据。 |
| [图片尺寸](image-resize.md) | 等比缩放、填充画布或居中裁剪图片。 |
| [SVG 工作台](svg.md) | 优化 SVG 源码并预览图形。 |
