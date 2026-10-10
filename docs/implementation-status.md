# 0.1.0 实现范围

更新：2026-10-10。72 个工具均已注册并有实际引擎；本页说明当前支持的子能力，不能把设计目录的全部进阶设想当成已交付。

主窗口已实现原生导航与系统玻璃、单工作区的工具会话缓存、搜索、收藏、参数、示例、复制、导出、原生编辑器与结果失效控制；常规工具新增内容自适应布局和共享会话的独立窗口。短文本使用结果卡片，长文本可选取复制；图片和 HTML/CSS 使用预览视图。

文件处理目前为单文件；工具默认参数、跨启动标签恢复、跨工具传递、自动转换与完整中英文本地化尚未实现。中文界面使用系统格式与原生菜单。

Spotlight 现有 2 个可发现通用入口与 2 个内部结果/复制动作；30 个旧动作停止公开发现并保留执行开关检查。设置管理 25 个本地轻量工具、命令别名和搜索实体索引，默认全部关闭。工具索引清空、单工具启用及别名冲突已在本机验证；系统 Spotlight 启动仍失败，完整命令与卡片链路尚未验收。详见 [验收记录](verification.md)。

## 模块列表

所有限制在模块说明、参数或结果提示中体现。源代码链接用于维护；共用组件不承载某个工具的业务状态。

| ID / 源码 | 工具 | 当前能力与边界 |
| --- | --- | --- |
| [base64](../Sources/DevKitCore/Tools/base64/Base64Tool.swift) | Base64 | 标准 / URL Safe；二进制需导出；Spotlight 系统链路待实测。 |
| [basic-auth](../Sources/DevKitCore/Tools/basic-auth/BasicAuthTool.swift) | Basic Auth | 生成与解析；用户名拒绝冒号；解析结果明确含明文凭证。 |
| [bitwise](../Sources/DevKitCore/Tools/bitwise/BitwiseTool.swift) | 位运算 | 8/16/32/64 位无符号；位宽之外输入拒绝。 |
| [border-radius](../Sources/DevKitCore/Tools/border-radius/BorderRadiusTool.swift) | 圆角生成 | 四角像素半径；尚无椭圆半径和联动操作。 |
| [box-shadow](../Sources/DevKitCore/Tools/box-shadow/BoxShadowTool.swift) | 阴影生成 | 单层、内阴影、偏移/模糊/扩散；尚无多层编辑器。 |
| [code-format](../Sources/DevKitCore/Tools/code-format/CodeFormatTool.swift) | 代码格式化 | Prettier JS/TS/HTML/CSS，SQL Formatter 多方言；不执行输入程序。 |
| [code-minify](../Sources/DevKitCore/Tools/code-minify/CodeMinifyTool.swift) | 代码压缩 | Terser 保守去空白/注释，CSSO，parse5 保守 HTML 压缩；不改名 JS 标识符。 |
| [color](../Sources/DevKitCore/Tools/color/ColorTool.swift) | 颜色转换 | sRGB HEX/RGB/HSL/透明度；逐格式复制；未实现色板保存。 |
| [compression](../Sources/DevKitCore/Tools/compression/CompressionTool.swift) | 压缩与解压 | Gzip / Zlib / raw Deflate；32 MiB 输出上限；拒绝多段流和尾随字节。 |
| [contrast](../Sources/DevKitCore/Tools/contrast/ContrastTool.swift) | 颜色对比度 | WCAG 2.2；不透明颜色，AA/AAA 条件明确。 |
| [cookie](../Sources/DevKitCore/Tools/cookie/CookieTool.swift) | Cookie | Cookie/单条 Set-Cookie 有序解析；尚无构建表单。 |
| [cron](../Sources/DevKitCore/Tools/cron/CronTool.swift) | Cron | 五字段，时区、固定起点、后续时间；不创建系统计划。 |
| [css-gradient](../Sources/DevKitCore/Tools/css-gradient/CssGradientTool.swift) | 渐变生成 | 双颜色线性/径向；暂未支持任意多色标。 |
| [css-unit](../Sources/DevKitCore/Tools/css-unit/CssUnitTool.swift) | CSS 单位 | px/rem/em/vw/vh；显式根字号、父字号与视口。 |
| [csv](../Sources/DevKitCore/Tools/csv/CsvTool.swift) | CSV 与 TSV | 分隔符、引号、换行、二维 JSON、转置；尚无可编辑表格和任意列操作。 |
| [cubic-bezier](../Sources/DevKitCore/Tools/cubic-bezier/CubicBezierTool.swift) | 缓动曲线 | 控制点与静态曲线；未加入播放动画。 |
| [curl-convert](../Sources/DevKitCore/Tools/curl-convert/CurlConvertTool.swift) | cURL 转换 | 静态解析常见参数为 fetch/JSON；拒绝 Shell 运算和 @文件。 |
| [data-url](../Sources/DevKitCore/Tools/data-url/DataUrlTool.swift) | Data URL | Base64 / 百分号载荷；不加载 Data URL 指向的活动内容。 |
| [date-time](../Sources/DevKitCore/Tools/date-time/DateTimeTool.swift) | 日期与时区 | 要求输入显式时区偏移；日历加天、时间差、时区对照；不接受歧义本地时间。 |
| [dns](../Sources/DevKitCore/Tools/dns/DnsTool.swift) | DNS 查询 | 系统 dig，八类记录，自定义解析器 IP/端口，3 秒单次超时。 |
| [favicon](../Sources/DevKitCore/Tools/favicon/FaviconTool.swift) | 网站图标 | PNG 尺寸集与 ICO，逐文件导出；无一键 ZIP 导出。 |
| [file-checksum](../Sources/DevKitCore/Tools/file-checksum/FileChecksumTool.swift) | 文件校验 | 单文件 32 MiB 内摘要和比较；当前通过有界文件读入，不支持大文件流式进度。 |
| [flex-grid](../Sources/DevKitCore/Tools/flex-grid/FlexGridTool.swift) | Flex 与 Grid | 常用 Flex/Grid 参数与预览；不是全量 CSS 布局编辑器。 |
| [format-convert](../Sources/DevKitCore/Tools/format-convert/FormatConvertTool.swift) | 数据格式互转 | 单文档 JSON/YAML/TOML/CSV；CSV 为二维标量数组，单元格按文本。 |
| [hash](../Sources/DevKitCore/Tools/hash/HashTool.swift) | 哈希摘要 | MD5/SHA-1/SHA-256/SHA-512；旧算法标识为兼容用途。 |
| [hex-text](../Sources/DevKitCore/Tools/hex-text/HexTextTool.swift) | Hex 文本 | 文本编码目前固定 UTF-8；非文本以 Hex 预览和二进制导出。 |
| [hmac](../Sources/DevKitCore/Tools/hmac/HmacTool.swift) | HMAC | SHA-256/SHA-512；UTF-8/Hex/Base64 密钥；Hex/Base64 输出。 |
| [html-entities](../Sources/DevKitCore/Tools/html-entities/HtmlEntitiesTool.swift) | HTML 实体 | HTML5 实体；严格解码；不渲染 HTML。 |
| [http-client](../Sources/DevKitCore/Tools/http-client/HttpClientTool.swift) | HTTP 调试 | HTTP/HTTPS 方法、头、正文、状态；临时会话，响应上限 5 MiB。 |
| [http-status](../Sources/DevKitCore/Tools/http-status/HttpStatusTool.swift) | HTTP 状态码 | 系统本地名称和常见状态说明；未收录状态明确指向 IANA。 |
| [image-compress](../Sources/DevKitCore/Tools/image-compress/ImageCompressTool.swift) | 图片压缩 | JPEG 有损质量与目标体积；明确提示不能达标；不宣称 PNG 无损优化。 |
| [image-convert](../Sources/DevKitCore/Tools/image-convert/ImageConvertTool.swift) | 图片格式转换 | 系统 PNG/JPEG/HEIC 编码，首帧；WebP 编码未开放。 |
| [image-metadata](../Sources/DevKitCore/Tools/image-metadata/ImageMetadataTool.swift) | 图片信息 | 信息查看和重新编码移除元数据；尚无逐字段选择性删除。 |
| [image-resize](../Sources/DevKitCore/Tools/image-resize/ImageResizeTool.swift) | 图片尺寸 | 单图等比放入/居中裁剪；PNG 输出；批量队列未实现。 |
| [json](../Sources/DevKitCore/Tools/json/JsonTool.swift) | JSON 工作台 | 无损数字；格式化、压缩、校验、路径条目；尚无可折叠节点树。 |
| [json-diff](../Sources/DevKitCore/Tools/json-diff/JsonDiffTool.swift) | JSON 结构对比 | JSON Pointer 路径差异；数组保持顺序，未加入忽略数组顺序策略。 |
| [json-path](../Sources/DevKitCore/Tools/json-path/JsonPathTool.swift) | JSON 路径 | JSON Pointer / JSONPath Plus 11；禁用求值表达式，不宣称完整 RFC 9535 方言。 |
| [json-schema](../Sources/DevKitCore/Tools/json-schema/JsonSchemaTool.swift) | JSON Schema | Draft 2020-12，Ajv 严格模式；本地引用；超精度数字拒绝校验。 |
| [json-to-model](../Sources/DevKitCore/Tools/json-to-model/JsonToModelTool.swift) | TypeScript 类型生成 | 从 JSON 样例推断 TypeScript；未实现 Schema 输入和其他语言。 |
| [jwt](../Sources/DevKitCore/Tools/jwt/JwtTool.swift) | JWT 工作台 | 解析与时间说明；仅 HS256 验签；不自动判断 aud/iss 业务可信度。 |
| [lorem-ipsum](../Sources/DevKitCore/Tools/lorem-ipsum/LoremIpsumTool.swift) | 占位文本 | 中英文段落、纯文本/HTML；暂未拆分句子计数模式。 |
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
| [slug](../Sources/DevKitCore/Tools/slug/SlugTool.swift) | Slug | Unicode 或拉丁转写 ASCII；横线/下划线连接。 |
| [string-escape](../Sources/DevKitCore/Tools/string-escape/StringEscapeTool.swift) | 字符串转义 | JSON 双引号字面量；未实现全部 JavaScript 字符串方言。 |
| [svg](../Sources/DevKitCore/Tools/svg/SvgTool.swift) | SVG 工作台 | 拒绝脚本/实体/外链；SVGO 优化与受限预览；尚无 SVG 栅格导出。 |
| [text-case](../Sources/DevKitCore/Tools/text-case/TextCaseTool.swift) | 命名与大小写 | camel/Pascal/snake/kebab/大写/小写；标点作为分词边界。 |
| [text-diff](../Sources/DevKitCore/Tools/text-diff/TextDiffTool.swift) | 文本对比 | 逐行增删与忽略行首尾空白；共 10000 行；尚无字符级高亮和差异跳转。 |
| [text-lines](../Sources/DevKitCore/Tools/text-lines/TextLinesTool.swift) | 文本行处理 | 排序、去重、去空行、编号、前后缀；保留原输入。 |
| [text-replace](../Sources/DevKitCore/Tools/text-replace/TextReplaceTool.swift) | 查找替换 | 普通或 ECMAScript 正则；结果与原文分离。 |
| [text-stats](../Sources/DevKitCore/Tools/text-stats/TextStatsTool.swift) | 文本统计 | 字素/码点/UTF-16/字节/行；词数按空白分隔。 |
| [timestamp](../Sources/DevKitCore/Tools/timestamp/TimestampTool.swift) | 时间戳 | 秒/毫秒显式，ISO 8601，当前时间；输入必须有限且在范围内。 |
| [toml](../Sources/DevKitCore/Tools/toml/TomlTool.swift) | TOML | TOML 1.1；JSON 导出时整数转字符串并明确提示。 |
| [ulid](../Sources/DevKitCore/Tools/ulid/UlidTool.swift) | ULID | 生成和时间解析；同毫秒独立随机，不提供单调工厂。 |
| [unicode-escape](../Sources/DevKitCore/Tools/unicode-escape/UnicodeEscapeTool.swift) | Unicode 转义 | UTF-16 与码点；拒绝孤立代理项。 |
| [unit-convert](../Sources/DevKitCore/Tools/unit-convert/UnitConvertTool.swift) | 单位转换 | 文件大小、时长、速率；SI/IEC 区分。 |
| [url-codec](../Sources/DevKitCore/Tools/url-codec/UrlCodecTool.swift) | URL 编解码 | 支持组件、完整 URL、WHATWG 表单字符集；解码要求 UTF-8。 |
| [url-parser](../Sources/DevKitCore/Tools/url-parser/UrlParserTool.swift) | URL 解析 | 只读分解与完整 URL 显示；尚无逐字段重组表单。 |
| [user-agent](../Sources/DevKitCore/Tools/user-agent/UserAgentTool.swift) | User Agent | 常见浏览器/系统启发式规则 v1；不是完整设备数据库。 |
| [uuid](../Sources/DevKitCore/Tools/uuid/UuidTool.swift) | UUID | RFC 9562 v4/v7；v7 同毫秒不保证单调性。 |
| [websocket](../Sources/DevKitCore/Tools/websocket/WebsocketTool.swift) | WebSocket 调试 | 专属界面手动连接/发送/接收/断开；1000 条/5 MiB；不持久化。 |
| [xml](../Sources/DevKitCore/Tools/xml/XmlTool.swift) | XML | XPath 1.0；拒绝 DTD/实体；保留混合文本的空白。 |
| [yaml](../Sources/DevKitCore/Tools/yaml/YamlTool.swift) | YAML | YAML 1.2，多文档，别名展开限制；无法精确表示的浮点数拒绝处理。 |

## 与发布有关的未完成项

- macOS 26 实机与真实 Spotlight A/B 全链路验收，包括 Quick Key 的完整关键词与原文参数传递。
- Developer ID 签名、公证、分发渠道及源代码许可证选择。
- Intel 设备运行测试；Release 产物含 arm64 / x86_64，但当前只在 Apple Silicon 实机测试。
- 上表明确未实现的高级编辑、批量处理和扩展格式能力，仍保留在原设计目录中。

当前定位为可运行自用版本，不声明原设计全部验收指标已满足。
