# 0.1.0 实现范围

更新：2026-10-10。48 个工具均已注册并有实际引擎；本页说明当前支持的子能力，不能把设计目录的全部进阶设想当成已交付。

主窗口已实现原生导航与系统玻璃、单工作区的工具会话缓存、搜索、收藏、参数、示例、复制、导出、原生编辑器与结果失效控制；常规工具新增内容自适应布局和共享会话的独立窗口。输入按场景区分表单、图片和代码；结果提供文本、条目与预览切换，图片可以复制和保存。

文件处理目前为单文件；工具默认参数、跨启动标签恢复、跨工具传递、自动转换与完整中英文本地化尚未实现。主界面仍以中文为主；顶部系统菜单与工具菜单跟随系统语言，支持简体中文、繁体中文和英文。

Spotlight 现有 2 个可发现通用入口与 2 个内部结果/复制动作；25 个旧动作停止公开发现并保留执行开关检查。设置管理 20 个本地轻量工具、命令别名和搜索实体索引，默认全部关闭。工具索引清空、单工具启用及别名冲突已在本机验证；系统 Spotlight 启动仍失败，完整命令与卡片链路尚未验收。详见 [验收记录](verification.md)。

## 模块列表

所有限制在模块说明、参数或结果提示中体现。源代码链接用于维护；共用组件不承载某个工具的业务状态。

| ID / 源码 | 工具 | 当前能力与边界 |
| --- | --- | --- |
| [base64](../Sources/DevKitCore/Tools/base64/Base64Tool.swift) | Base64 | 标准 / URL Safe 的 UTF-8 文本；非 UTF-8 明确拒绝；Spotlight 系统链路待实测。 |
| [code-format](../Sources/DevKitCore/Tools/code-format/CodeFormatTool.swift) | 代码格式化 | Prettier JS/TS/HTML/CSS，SQL Formatter 多方言；不执行输入程序。 |
| [code-minify](../Sources/DevKitCore/Tools/code-minify/CodeMinifyTool.swift) | 代码压缩 | Terser 保守去空白/注释，CSSO，parse5 保守 HTML 压缩；不改名 JS 标识符。 |
| [color](../Sources/DevKitCore/Tools/color/ColorTool.swift) | 颜色转换 | sRGB HEX/RGB/HSL/透明度；逐格式复制；未实现色板保存。 |
| [contrast](../Sources/DevKitCore/Tools/contrast/ContrastTool.swift) | 颜色对比度 | WCAG 2.2；不透明颜色，AA/AAA 条件明确。 |
| [cookie](../Sources/DevKitCore/Tools/cookie/CookieTool.swift) | Cookie | Cookie/单条 Set-Cookie 有序解析；尚无构建表单。 |
| [cron](../Sources/DevKitCore/Tools/cron/CronTool.swift) | Cron | 五字段，时区、固定起点、后续时间；不创建系统计划。 |
| [css-unit](../Sources/DevKitCore/Tools/css-unit/CssUnitTool.swift) | CSS 单位 | px/rem/em/vw/vh；显式根字号、父字号与视口。 |
| [curl-convert](../Sources/DevKitCore/Tools/curl-convert/CurlConvertTool.swift) | cURL 转换 | 静态解析常见参数为 fetch/JSON；拒绝 Shell 运算和 @文件。 |
| [data-url](../Sources/DevKitCore/Tools/data-url/DataUrlTool.swift) | Data URL | 图片编码为 Data URL；解码保留原始图片字节与格式，支持预览、复制和导出。自动识别 MIME 并校验图片；文本 Data URL 上限 5 MiB；不接受 SVG 或非图片载荷。 |
| [date-time](../Sources/DevKitCore/Tools/date-time/DateTimeTool.swift) | 日期与时区 | 原生日期时间选择、输入/目标时区选择；日历加天和实际时间差，结果按所选时区显示。 |
| [dns](../Sources/DevKitCore/Tools/dns/DnsTool.swift) | DNS 查询 | 系统 dig，八类记录，自定义解析器 IP/端口，3 秒单次超时。 |
| [favicon](../Sources/DevKitCore/Tools/favicon/FaviconTool.swift) | 网站图标 | PNG 尺寸集与 ICO，逐文件导出；无一键 ZIP 导出。 |
| [file-checksum](../Sources/DevKitCore/Tools/file-checksum/FileChecksumTool.swift) | 文件校验 | 原生选取文件使用流式摘要和比较，无 32 MiB 整体读入限制；显示读取进度并支持取消。 |
| [hash](../Sources/DevKitCore/Tools/hash/HashTool.swift) | 哈希摘要 | MD5/SHA-1/SHA-256/SHA-512；旧算法标识为兼容用途。 |
| [hmac](../Sources/DevKitCore/Tools/hmac/HmacTool.swift) | HMAC | SHA-256/SHA-512；UTF-8/Hex/Base64 密钥；Hex/Base64 输出。 |
| [http-client](../Sources/DevKitCore/Tools/http-client/HttpClientTool.swift) | HTTP 调试 | HTTP/HTTPS 方法、头、正文、状态；临时会话，响应上限 5 MiB。 |
| [http-status](../Sources/DevKitCore/Tools/http-status/HttpStatusTool.swift) | HTTP 状态码 | 系统本地名称和常见状态说明；未收录状态明确指向 IANA。 |
| [image-compress](../Sources/DevKitCore/Tools/image-compress/ImageCompressTool.swift) | 图片压缩 | JPEG 有损质量与目标体积；明确提示不能达标；不宣称 PNG 无损优化。 |
| [image-convert](../Sources/DevKitCore/Tools/image-convert/ImageConvertTool.swift) | 图片格式转换 | 系统 PNG/JPEG/HEIC 编码，首帧；WebP 编码未开放。 |
| [image-metadata](../Sources/DevKitCore/Tools/image-metadata/ImageMetadataTool.swift) | 图片信息 | 信息查看和重新编码移除元数据；尚无逐字段选择性删除。 |
| [image-resize](../Sources/DevKitCore/Tools/image-resize/ImageResizeTool.swift) | 图片尺寸 | 默认等比缩放到宽高边界内，可选透明画布或居中裁剪；PNG 输出；批量队列未实现。 |
| [json](../Sources/DevKitCore/Tools/json/JsonTool.swift) | JSON 工作台 | 统一入口：格式化、压缩、校验、路径列表、JSONPath/Pointer、结构对比、Draft 2020-12 Schema 校验与 TypeScript 类型推断。模式切换保留源 JSON，并分别保留对比文档与 Schema。 |
| [jwt](../Sources/DevKitCore/Tools/jwt/JwtTool.swift) | JWT 工作台 | 解析与时间说明；仅 HS256 验签；不自动判断 aud/iss 业务可信度。 |
| [markdown](../Sources/DevKitCore/Tools/markdown/MarkdownTool.swift) | Markdown | HTML 白名单清理；禁止外部资源；不支持活动嵌入。 |
| [mime-types](../Sources/DevKitCore/Tools/mime-types/MimeTypesTool.swift) | MIME 类型 | 系统 UTType 数据库；范围随系统版本变化。 |
| [mock-data](../Sources/DevKitCore/Tools/mock-data/MockDataTool.swift) | Mock 数据 | 六类字段，JSON/CSV，可重复种子；不提供真实身份，不用于安全凭证。 |
| [nanoid](../Sources/DevKitCore/Tools/nanoid/NanoidTool.swift) | Nano ID | 安全随机与自定义字符集；总字符上限 100000。 |
| [number-base](../Sources/DevKitCore/Tools/number-base/NumberBaseTool.swift) | 进制转换 | BigInt 精确进制转换，带符号；补码另在无符号位工具处理。 |
| [number-format](../Sources/DevKitCore/Tools/number-format/NumberFormatTool.swift) | 数字格式 | Decimal，38 位有效数字，舍入/分组；暂不输出科学计数法。 |
| [pem-certificate](../Sources/DevKitCore/Tools/pem-certificate/PemCertificateTool.swift) | PEM 与证书 | 首张 PEM/DER X.509 的主题、有效期、SHA-256；不验信任链，不解析私钥。 |
| [qr-code](../Sources/DevKitCore/Tools/qr-code/QrCodeTool.swift) | 二维码 | Core Image 生成带静区 PNG；Vision 识别文本 QR；最多 2000 UTF-8 字节。 |
| [query-string](../Sources/DevKitCore/Tools/query-string/QueryStringTool.swift) | 查询参数 | 有序键值 JSON、重复键、空值、排序、生成；不提供电子表格式编辑。 |
| [random-string](../Sources/DevKitCore/Tools/random-string/RandomStringTool.swift) | 随机字符串 | 安全随机、无偏采样、Unicode 字符集；总字符上限 100000。 |
| [regex](../Sources/DevKitCore/Tools/regex/RegexTool.swift) | 正则测试 | ECMAScript 标志、捕获和替换；隔离执行，最多 10000 个匹配。 |
| [svg](../Sources/DevKitCore/Tools/svg/SvgTool.swift) | SVG 工作台 | 拒绝脚本/实体/外链；SVGO 优化与受限预览；尚无 SVG 栅格导出。 |
| [text-case](../Sources/DevKitCore/Tools/text-case/TextCaseTool.swift) | 命名与大小写 | camel/Pascal/snake/kebab/大写/小写；标点作为分词边界。 |
| [text-diff](../Sources/DevKitCore/Tools/text-diff/TextDiffTool.swift) | 文本对比 | 逐行增删与忽略行首尾空白；共 10000 行；尚无字符级高亮和差异跳转。 |
| [text-lines](../Sources/DevKitCore/Tools/text-lines/TextLinesTool.swift) | 文本行处理 | 排序、去重、去空行、编号、前后缀；保留原输入。 |
| [text-replace](../Sources/DevKitCore/Tools/text-replace/TextReplaceTool.swift) | 查找替换 | 普通或 ECMAScript 正则；结果与原文分离。 |
| [text-stats](../Sources/DevKitCore/Tools/text-stats/TextStatsTool.swift) | 文本统计 | 字素/码点/UTF-16/字节/行；词数按空白分隔。 |
| [timestamp](../Sources/DevKitCore/Tools/timestamp/TimestampTool.swift) | 时间戳 | 秒/毫秒与普通日期互转、时区选择、当前时间；保留毫秒精度并检查日期范围。 |
| [ulid](../Sources/DevKitCore/Tools/ulid/UlidTool.swift) | ULID | 生成和时间解析；同毫秒独立随机，不提供单调工厂。 |
| [unit-convert](../Sources/DevKitCore/Tools/unit-convert/UnitConvertTool.swift) | 单位转换 | 文件大小、时长、速率；SI/IEC 区分。 |
| [url-codec](../Sources/DevKitCore/Tools/url-codec/UrlCodecTool.swift) | URL 编解码 | 支持组件、完整 URL、WHATWG 表单字符集；解码要求 UTF-8。 |
| [url-parser](../Sources/DevKitCore/Tools/url-parser/UrlParserTool.swift) | URL 解析 | 只读分解与完整 URL 显示；尚无逐字段重组表单。 |
| [uuid](../Sources/DevKitCore/Tools/uuid/UuidTool.swift) | UUID | RFC 9562 v4/v7；v7 同毫秒不保证单调性。 |
| [websocket](../Sources/DevKitCore/Tools/websocket/WebsocketTool.swift) | WebSocket 调试 | 专属界面手动连接/发送/接收/断开；1000 条/5 MiB；不持久化。 |

## 与发布有关的未完成项

- macOS 26 实机与真实 Spotlight A/B 全链路验收，包括 Quick Key 的完整关键词与原文参数传递。
- Developer ID 签名、公证、分发渠道及源代码许可证选择。
- Intel 设备运行测试；Release 产物含 arm64 / x86_64，但当前只在 Apple Silicon 实机测试。
- 上表明确未实现的高级编辑、批量处理和扩展格式能力，仍保留在原设计目录中。

当前定位为可运行自用版本，不声明原设计全部验收指标已满足。
