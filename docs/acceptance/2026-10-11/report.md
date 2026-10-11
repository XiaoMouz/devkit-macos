# 48 个工具实机操作验收记录

> 归档说明：本文件保留验收结论。截图、日志、采样和中间产物已移至仓库外；“归档”路径相对于原报告所在目录。详见[资料管理说明](../README.md)。

后续已完成子模式和极端输入补测，新增问题与最终资源读数见 [最终补测报告](expanded/report.md)。本文保留首轮原始范围与结果。

日期：2026-10-11（Asia/Shanghai）。结论：**48/48 个工具已通过桌面 UI 逐一实际操作并取得结果；本轮不等于所有子功能、所有边界均已验收通过。** 未运行单元测试或用引擎调用替代界面操作，未修改产品代码。

优先处理的是使用后的常驻内存、短结果的滚动位置，以及失败状态仍显示旧结果计数。未观察到应用崩溃或持续无法交互；正则和较大源码存在约 1–2 秒的可感知等待。

## 环境与证据口径

- 设备：Apple M3 / Mac15,3 / 16 GiB；macOS 27.0.1（26A434）。不代表 macOS 26 或 Intel 已验收。
- 工程：`DevKit.xcodeproj`，scheme `DevKit`，destination `My Mac`。接管时 Xcode 已处于 Run / Debug，调试导航确认 DevKit PID **47490**；全程使用该实例，没有另建、安装或启动另一份 App。
- 仓库起止提交均为 `cafa905`；开始时工作区干净，验收期间无产品源码变化。Debug、调试器、桌面自动操作及屏幕观察均可能影响数据，不能外推 Release 性能。
- 实际操作包括搜索、输入、切换选项、执行、复制粘贴、结果视图切换、原生文件打开/保存、连接/发送/断开。界面证据在 evidence（归档：`evidence/`），操作样本与导出产物在 fixtures（归档：`fixtures/`），校验清单见 fixture-manifest.json（归档：`fixture-manifest.json`）。AX 文本可能仅包含可见文本片段，不能把它当完整导出文件。
- process-samples.csv（归档：`process-samples.csv`） 为约 0.5 秒间隔的 `ps` 采样，时间为本日 01:08:59–01:30:14，共 2335 条进程记录，记录主进程及采样时能追踪到的 DevKit worker/子进程。**不包括已由 launchd 托管、无法仅靠父子关系归属的全部 WebKit 进程，因此合计是下界，不是完整应用总 footprint。** 短暂峰值也可能漏采。
- Xcode Memory、RSS、峰值和空闲值分别记录，不混用单位或相加。CPU 的 100% 约为一个逻辑核心，进程相加可超过 100%。
- 采样阶段是连续使用场景；同名阶段含后续复核和清理。阶段峰值含历史会话影响，不能解释成某个工具单独启动的净占用。
- HTTP / WebSocket 使用仅绑定 `127.0.0.1:18765` 的专用回显服务，只有虚构文本；验收后已停止。DNS 使用系统解析器查询 `example.com`。首次 WebSocket 失败来自样本服务返回 HTTP/1.0，修正服务为 HTTP/1.1 后成功，不计为产品故障。

## 内存与等待时间

### Xcode 实际读数

| 场景 | Xcode Memory | 说明 |
| --- | ---: | --- |
| 接管现有调试实例，时间戳页面 | 87.5 MB | 初始观察，不是冷启动基准 |
| 连续操作前 19 个工具后 | 129.5 MB | 调试导航证据（归档：`evidence/xcode-after19.txt`） |
| 大文本与 2000 条 JSON 操作后 | 241.9 MB | 调试导航证据（归档：`evidence/xcode-after-stress.txt`）；此时曾显示 CPU 63%，后续空闲采样已回落 |
| 清空 Base64、JSON、代码格式化的大输入及大图，停止 WebSocket 后 | 228.6 MB | CPU 0%，Energy Low；截图（归档：`evidence/xcode-idle-after-cleanup.png`）、文本（归档：`evidence/xcode-idle-after-cleanup.txt`） |

项目记录的使用后 100 MB 目标本轮**未达到**，仅主进程读数就已超过目标。清理后仍有其他轻量工具会话；未做堆分配归因，不将这组增长直接定性为泄漏。

### 实际工作负载

| UI 操作 | 输入 | 界面显示耗时 | 采样主进程 RSS 峰值 | 可追踪进程合计 RSS 峰值 |
| --- | --- | ---: | ---: | ---: |
| 正则 `(a+)+$`，不匹配 | 32 个 `a` 加 `!` | 1.9 s | 212.9 MiB | 308.8 MiB |
| Base64 编码 | 100 KiB ASCII | 未显示耗时 | 218.0 MiB | 218.0 MiB |
| Base64 编码、完整复制、解码 | 1 MiB ASCII；编码结果 1,398,104 字符 | 解码 1.1 s | 284.6 MiB | 312.2 MiB |
| JSON 格式化与折叠预览 | 2000 条，164,781 字节 | 272 ms | 285.6 MiB | 395.7 MiB |
| JavaScript 格式化 | 3000 行，153,779 字节 | 1.7 s | 273.2 MiB | 397.7 MiB |
| 图片压缩到目标 100 KB | 4096×4096 RGBA PNG，603,142 字节 | 527 ms | 272.9 MiB | **468.5 MiB** |

完整阶段数据见 [memory-summary.csv](memory-summary.csv)，原始数据见 process-samples.csv（归档：`process-samples.csv`）。源码格式化阶段采样 CPU 合计峰值 162.3%，回溯正则约 100.3%。这反映任务期间的计算负载，未证明 UI 主线程持续阻塞。

粘贴与读取界面的操作总耗时，100 KiB Base64 约 1.5 秒、1 MiB 约 2.8 秒、JSON 约 3.0 秒；**包含电脑控制和 AX 读取开销，不作为纯粘贴延迟或帧率成绩**。未测量输入到首帧的严格延迟，也不能据此宣称 200 ms 指标通过或失败。

## 已确认问题与优化优先级

### P1：使用后常驻内存未达到目标

连续使用后主进程从初始 87.5 MB 上升，清理大输入后仍为 228.6 MB。图片压缩期间可追踪进程 RSS 合计峰值 468.5 MiB；约 150 KiB 源码/JSON 的阶段峰值也接近 400 MiB。

建议先用 Xcode Memory Graph / Instruments 对当前 Run 实例做分配归因，分别核对工具会话、编辑器 undo/文本存储、图片解码缓冲、预览及 worker 生命周期。按“完成后、切走后、清空后”比较存活对象，建立会话缓存的容量上限。图片预览采用适配显示尺寸的缓冲，避免任务中同时保留多份全分辨率解码数据。以上是定位方向，尚未用堆证据认定某个对象泄漏。

### P2：短结果可能被此前滚动位置遮住

在正则工具中先匹配、切到无匹配结果，再用 `\d+` 对 `abc` 执行：状态显示完成、2 字符、0 个匹配，AX 值为 `[]`，但结果编辑区仅见行号，文本区域空白。点击结果区，使用 `⌘←` / `Home` 后 `[]` 出现。

证据：空白结果截图（归档：`evidence/recheck-regex-zero.png`）、选中后仍空白（归档：`evidence/recheck-regex-empty-visible.png`）、回到起点后可见（归档：`evidence/recheck-regex-blank-result.png`）。建议新结果替换旧结果时重置或限制可视滚动范围，并检查行号栏、文本容器原点及选区恢复。尚未确认是横向偏移还是重绘时机，不能仅凭截图认定根因。

### P2：执行失败仍显示上次成功结果的字符数

Base64 解码 `aGVsbG8=` 得到 `hello` 后，将输入改为 `%%%` 并执行。结果区正确报错、复制/导出禁用，但右下角仍为 **5 字符**。该问题已通过截图确认，SVG 拒绝输入、HTTP 超限等路径也在 AX 中出现旧计数。

证据：失败页面截图（归档：`evidence/recheck-base64-error-footer.png`）、界面记录（归档：`evidence/recheck-base64-error-footer.txt`）。建议失败时隐藏旧长度，或明确标为“上次结果 5 字符”。当前错误文案还在顶部和中央重复出现，可合并成一次说明及重试指引。

### P2：图片结果默认缺少最有用的信息

图片尺寸、转换、压缩等工具的默认结果为预览，底部显示“21 字符 / 20 字符 / 25 字符”，无法直接判断新尺寸或体积。必须打开“预览 → 文本”才看到 `800×400 → 200×100` 或 `603142 → 268176 字节`。

证据：压缩默认预览（归档：`evidence/41-image-compress-done.png`）、体积文本（归档：`evidence/41-image-compress-size.txt`）、尺寸文本（归档：`evidence/39-image-resize-dimensions.txt`）。建议预览旁常驻原/目标尺寸、格式、体积、节省比例；未达到目标大小时使用醒目的警告状态，本例虽有说明但底部仍为绿色“已完成”。

### P3：工具信息与操作成本

| 工具 | 实际观察 | 建议 |
| --- | --- | --- |
| JWT | 已过期的 `exp=1` 令牌可正确验签；界面提示仍需检查 exp，并显示 1970 年日期，但没有直接的“已过期”状态 | 将签名有效性与过期/尚未生效分开展示，不将签名有效改成业务可信 |
| HTTP 状态码 | 429 的中文含义是“请求过多”，英文状态为系统返回的 `client error` | 常见状态补充更具体的英文名称；保留系统来源说明 |
| 网站图标 | 生成六张 PNG 和 ICO，导出菜单需逐个保存 | 增加“全部导出到文件夹/ZIP”；属于现有范围的优化，不标为功能故障 |
| 日期/时区 | 常用时区可用，但完整菜单有数百项，缺少搜索入口 | 支持按城市/标识/UTC 偏移过滤，保留常用项 |
| Mock 数据 | 表单字段显示 active/email/id/name/score，CSV 列为 id/name/email/active/score | 统一显示顺序与输出列顺序，或显式提供排序/拖动 |
| 文件校验 | 33 MiB 文件在导入阶段被拒绝，符合现有 32 MiB 边界 | 面向真实安装包/压缩包时改为流式摘要并提供进度、取消；当前不能处理常见大文件 |

## 需进一步确认、不能当作功能缺陷的观察

- **AX 与画面不一致**：重复执行时，AX 曾保留旧正则匹配数、JWT 验签标题、HTTP 字节数、日期值。实际截图中的正则数量正确；切走再回来后 AX 也恢复。证据：两次匹配的截图（归档：`evidence/recheck-regex-two-settled.png`）与仍读为零的 AX（归档：`evidence/recheck-regex-two-settled.txt`）。可能涉及应用无障碍发布或观察层缓存，需要独立 AX/VoiceOver 验证；不计为正则、验签或时区算法错误。
- 时区转换最终为上海 `2026-10-11 12:00:00` → UTC `04:00:00`，见复核截图（归档：`evidence/21-date-time-final-correct.png`）。快速点菜单后马上执行时曾取得待更新的旧结果，分步确认后正常。
- 编辑参数后立即执行、随后切走，在个别工具返回时出现“待更新”。没有完成排除控件提交时序的独立复现，暂不认定会话缓存损坏。
- 原生文件面板曾发生快速粘贴未生效；分步定位并确认文件存在后成功。不计为导入故障。一次 JPEG 保存面板被外部 UI 变化关闭，本轮不宣称 JPEG 已成功落盘。
- Xcode 控制台有 WebKit sandbox / RunningBoard / pasteboard 相关系统诊断，预览实际可用；未把这些日志直接归为崩溃，也没有关闭任何保护或屏蔽日志。

## 48 个工具逐项实际操作

“主流程可用”只指本行描述的操作；未操作的其他模式不自动通过。编号是本轮操作序号。

| # | 工具 | 实际操作及核对结果 | 结论 / 证据 |
| --- | --- | --- | --- |
| 01 | 时间戳 | 输入 Unix 秒 `0`，得到上海 `1970-01-01 08:00:00.000`、秒/毫秒均为 0 | 主流程可用；记录（归档：`evidence/01-timestamp.txt`） |
| 02 | Base64 | `hello 你好🌍` 加 LF 编码、复制、粘贴、解码；非法 `%%%` 拒绝；另做 100 KiB/1 MiB 往返 | 主流程可用，有旧计数问题；往返（归档：`evidence/02-base64-roundtrip.txt`） |
| 03 | URL 编解码 | `a+b 你好/?&=` 编码；百分号中文与 `%2B` 解码为 `你好+` | 主流程可用；编码（归档：`evidence/03-url-encode.txt`）、解码（归档：`evidence/03-url-decode.txt`） |
| 04 | JSON 工作台 | 格式化含 `9007199254740993` 的文档，整数保真；折叠数组；JSONPath `$.items[1]` 得到 `[true]`；另做 2000 条预览 | 已测路径可用；路径（归档：`evidence/04-json-path.txt`）、大文档（归档：`evidence/stress-json-2000rows-complete.png`） |
| 05 | 哈希摘要 | `abc` 的 SHA-256 为 `ba7816bf…0015ad` | 主流程可用；记录（归档：`evidence/05-hash.txt`） |
| 06 | HMAC | key=`key`，消息为 quick brown fox 标准句，SHA-256 为 `f7bc83f4…a3cd8` | 主流程可用；记录（归档：`evidence/06-hmac.txt`） |
| 07 | JWT 工作台 | 虚构 HS256 令牌，正确密钥通过，错误密钥未通过；检查 iat/exp | 主流程可用，过期提示可优化；正确（归档：`evidence/07-jwt-valid-signature-expired.txt`）、错误（归档：`evidence/07-jwt-invalid-rerun.txt`） |
| 08 | UUID | 实际生成 5 个 UUID v4，版本位和变体符合预期，五条不同 | 已测 v4 可用；记录（归档：`evidence/08-uuid-v4.txt`） |
| 09 | ULID | 生成 5 条，复制第一条到解析模式，得到本次生成时间与毫秒 | 主流程可用；解析（归档：`evidence/09-ulid-parse.txt`） |
| 10 | Nano ID | 长度 8、数量 5、自定义 `ABC123` 字符集 | 输出数量、长度、字符集正确；记录（归档：`evidence/10-nanoid-custom.txt`） |
| 11 | 随机字符串 | 长度 8、数量 5、字符集 `甲乙🌍` | Unicode 结果完整；记录（归档：`evidence/11-random-unicode.txt`） |
| 12 | Mock 数据 | 种子 42 生成 3 条 CSV，再执行一次 | 两次相同；字段顺序可优化；首次（归档：`evidence/12-mock-csv.txt`）、重复（归档：`evidence/12-mock-repeat.txt`） |
| 13 | 正则测试 | 两个邮箱的捕获组；回溯表达式；`\d+` 匹配 `1 2`、`abc` | 计算结果可用，短结果显示问题；首次（归档：`evidence/13-regex-match.txt`）、复核（归档：`evidence/recheck-regex-zero.txt`） |
| 14 | 文本对比 | beta 改 BETA，追加 delta，结果 2 新增/1 删除；切高亮 | 主流程可用；明细（归档：`evidence/14-text-diff.txt`）、高亮（归档：`evidence/14-text-diff-highlight.png`） |
| 15 | 文本统计 | `A你🌍e` 加组合重音及 LF | 字素 5、码点 6、UTF-16 7、UTF-8 12 字节、2 行；记录（归档：`evidence/15-text-stats.txt`） |
| 16 | 文本行处理 | 多行 beta/alpha 重复、空行、中文，执行去重 | 保留首次顺序及一个空行；记录（归档：`evidence/16-text-lines-dedupe.txt`） |
| 17 | 命名与大小写 | `hello-world API_client` → camelCase | `helloWorldApiClient`；记录（归档：`evidence/17-text-case.txt`） |
| 18 | 查找替换 | `(foo)(\d+)`，替换 `$2-$1`，输入 `foo12 foo34 你好` | `12-foo 34-foo 你好`；记录（归档：`evidence/18-text-replace.txt`） |
| 19 | Markdown | 标题、加粗、代码、列表、表格及 script 标签预览 | 正常渲染，未执行 BAD 脚本；记录（归档：`evidence/19-markdown-settled.png`） |
| 20 | Cron | `*/15 9-18 * * 1-5`，上海时区，预览 10 次 | 从周一 10 月 12 日 09:00 起，每 15 分钟；记录（归档：`evidence/20-cron.txt`） |
| 21 | 日期与时区 | 示例上海 12:00，选择 UTC，执行并复核 | UTC 04:00；最终记录（归档：`evidence/21-date-time-final-correct.txt`） |
| 22 | 进制转换 | 十进制 `9007199254740993` 转十六进制 | `20000000000001`，并列二/八/十进制；记录（归档：`evidence/22-number-base.txt`） |
| 23 | 数字格式 | `1234567.895`，两位小数、四舍五入、分组 | `1,234,567.90`；记录（归档：`evidence/23-number-format.txt`） |
| 24 | 单位转换 | `1.5 KiB` → B | `1536 B`；记录（归档：`evidence/24-unit-convert.txt`） |
| 25 | 颜色转换 | `#ff000080` | HEX/RGB/HSL 与约 0.502 alpha；记录（归档：`evidence/25-color-alpha.txt`） |
| 26 | 颜色对比度 | 白色前景、黑色背景 | `21.00:1`，显示 AA/AAA 通过；记录（归档：`evidence/26-contrast.txt`） |
| 27 | CSS 单位 | 24px，根字号 16px，转 rem | `1.5rem`；记录（归档：`evidence/27-css-unit.txt`） |
| 28 | URL 解析 | 含 8443 端口、`/a%20b`、重复 tag、空参数与 fragment | 各字段完整；记录（归档：`evidence/28-url-parser.txt`） |
| 29 | 查询参数 | `q=hello+world&tag=a&tag=b&empty=&flag` | 重复键保留、空值/无值区分、+ 解为空格；记录（归档：`evidence/29-query-string.txt`） |
| 30 | Cookie | 单条 Set-Cookie，含 Path、Max-Age、HttpOnly、Secure、SameSite | 属性正确，值不自动 URL 解码；记录（归档：`evidence/30-cookie.txt`） |
| 31 | HTTP 状态码 | 输入 429 查询 | 中文正确，英文名称泛化；记录（归档：`evidence/31-http-status.txt`） |
| 32 | MIME 类型 | 查询 png | image/png、public.png；记录（归档：`evidence/32-mime.txt`） |
| 33 | cURL 转换 | POST、Content-Type、中文 JSON body → fetch | 方法、头、转义正文保留；记录（归档：`evidence/33-curl.txt`） |
| 34 | 代码格式化 | JS 对象/函数格式化；3000 行源码 | 输出可用；大样本 1.7 s；普通（归档：`evidence/34-code-format.txt`）、压力（归档：`evidence/stress-code-format-complete.txt`） |
| 35 | 代码压缩 | JS 注释、空白、字符串中的 `https://…/a//b` | 移除注释，字符串与标识符保留；记录（归档：`evidence/35-code-minify.txt`） |
| 36 | SVG 工作台 | 红色矩形优化预览，再输入 script | 图形正常，脚本输入拒绝；预览（归档：`evidence/36-svg-rendered.png`）、拒绝（归档：`evidence/36-svg-reject.txt`） |
| 37 | 二维码 | 中文/Emoji/URL 生成、原生保存、重新导入、识别 | 完整还原；390×390 PNG；回读（归档：`evidence/37-qr-recognize.txt`） |
| 38 | Data URL | 导入透明 PNG → Data URL；复制到解码模式 | 146,918 字符，解码得到图片；编码（归档：`evidence/38-data-url-encode.txt`）、预览（归档：`evidence/38-data-url-roundtrip.png`） |
| 39 | 图片尺寸 | 800×400 PNG 等比缩至 200×200 边界 | 实际 200×100；记录（归档：`evidence/39-image-resize-dimensions.txt`） |
| 40 | 图片格式转换 | 透明 PNG → JPEG，质量 85 | 得到预览，明确提示透明合成白色；JPEG 保存未确认；记录（归档：`evidence/40-image-convert-jpeg.txt`） |
| 41 | 图片压缩 | 4096 大图，质量上限 85，目标 100 KB | 603142 → 268176 字节；明确说明无法达标；记录（归档：`evidence/41-image-compress-size.txt`） |
| 42 | 图片信息 | 读取透明 PNG，再启用移除元数据并实际保存 | 800×400、RGB、8 位、alpha；导出文件的原始 tEXt Comment 已移除；记录（归档：`evidence/42-image-info-saved.txt`） |
| 43 | 网站图标 | 从 PNG 生成尺寸集，通过菜单实际导出 ICO | 六张 PNG 可选；导出 ICO 回读含 16/32/48 三项；记录（归档：`evidence/43-favicon-export.txt`） |
| 44 | 文件校验 | 导入 abc.txt；错误期望摘要；再选择 33 MiB 文件 | SHA-256 正确、不匹配明确、超限拒绝；摘要（归档：`evidence/44-checksum.txt`）、超限（归档：`evidence/44-checksum-overlimit.txt`） |
| 45 | PEM 与证书 | 原生导入专用自签 PEM，读取主题、起止时间、指纹 | 与导出证书读回核对一致；记录（归档：`evidence/45-pem.txt`） |
| 46 | DNS 查询 | example.com / A / 系统解析器 | NOERROR、两条 A、显示解析器和 15 ms 查询时间；记录（归档：`evidence/46-dns-running.txt`） |
| 47 | HTTP 调试 | 本机 GET、POST 中文正文、15 秒慢响应取消、6 MiB 响应 | 200/回显正常、实际取消、5 MiB 上限拒绝；GET（归档：`evidence/47-http-get.txt`）、POST（归档：`evidence/47-http-post.txt`）、取消（归档：`evidence/47-http-cancelled.txt`）、超限（归档：`evidence/47-http-overlimit-confirmed.txt`） |
| 48 | WebSocket 调试 | 连接、发送中文/Emoji/LF、接收、切换工具、再次发送、断开 | 收发共 4 条，切换后连接保留，断开成功；回显（归档：`evidence/48-websocket-echo.txt`）、断开（归档：`evidence/48-websocket-disconnect.txt`） |

## 本轮边界

本轮覆盖每个工具至少一个有意义的实际流程，并额外覆盖代表性错误、文件回读、取消、大文本和大图。未穷尽 JSON Schema/结构对比/类型推断、UUID v7、所有编码变体、全部格式化语言、HEIC、图片裁剪/透明画布、所有 DNS 记录、WebSocket 长时间/上限压力等子模式。

未进行本轮 Spotlight、发布签名/归档、系统外观矩阵、VoiceOver 全程、最小窗口/多显示器、冷启动基准或严格帧率测量；不能从本报告推断这些已通过。文件产物读取只用于确认实际 UI 导出的字节和元数据，没有绕过 UI 调用产品引擎。

建议下一轮先修复可见结果显示与错误计数，再以相同样本复测内存；利用 Xcode 对 48 会话使用后的存活对象和 worker 峰值做归因。保留主流程能力，避免通过限制常用输入或移除预览来掩盖资源问题。
