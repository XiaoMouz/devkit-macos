# 48 个工具：子模式与极端场景实操验收

> 归档说明：本文件保留验收结论。截图、日志、采样和中间产物已移至仓库外；“归档”路径相对于原报告所在目录。详见[资料管理说明](../../README.md)。

日期：2026-10-11。**已完成 48 个工具的功能、算法、格式子模式逐项操作及本报告列出的边界补测，结论为“有问题，不能全部验收通过”。** 本轮补测保存 768 条操作记录、719 个唯一证据 ID，包含导航、导入、导出和复核，不能称为 768 个通过的测试。

全程操作 Xcode 当前 Run / Debug 实例：DevKit scheme、My Mac、PID 47490、源码提交 cafa905。没有用引擎调用或单元测试替代界面操作，没有修改产品代码。锁屏后在用户解锁的同一实例继续，没有另行构建或启动 App。首轮 48 项主流程及早期资源数据见[首轮报告](../report.md)。

“子模式覆盖”指下表列明的有限功能选择；数值、文本、所有时区和网络故障组合不存在可穷尽的有限集合。本轮实际做了上下限、越界、损坏输入、Unicode、精度、DST、取消、重连、批量、导出读回和大输入；不把未测环境或任意输入组合写成通过。

## 优先处理的问题

| 优先级 | 实际复现 | 影响与建议 | 证据 |
| --- | --- | --- | --- |
| P1 | 数字格式输入 1.12345678901234567890，保留 20 位，输出 1.12345678901235000000；重复执行一致 | 宣称最多 38 位有效数字，但小数输出发生精度损失。核对 Decimal → NumberFormatter 的格式化链路，使用能保留十进制有效位的输出方式。整数 9007199254740993 正常，不能将范围缩小为“大整数不支持” | 文本（归档：`evidence/number-precision-20.txt`）、画面（归档：`evidence/number-precision-20.png`） |
| P1 | 连续使用并清空主要大输入、图片后，Xcode Memory 仍为 379.4 MB，CPU 0%；末尾主进程 RSS 270.09 MiB | 使用后 100 MB 目标未达到。需要 Xcode Memory Graph / Instruments 区分会话、文本/undo、图片、预览及 worker 的保留；本轮没有堆证据，不能直接定性泄漏 | 最终 Xcode 读数（归档：`evidence/xcode-final-idle.txt`）、[资源汇总](resource-final-summary.json) |
| P2 | 多行 Set-Cookie: a=1 与 Set-Cookie: b=2 被合并成一个名称和值 | 应逐条解析，或明确拒绝多行输入，不能静默生成错误结果 | 记录（归档：`evidence/cookie-multiple-headers.txt`） |
| P2 | 正则 9999 项成功，恰好 10000 项却报“匹配超过 10000 项” | 实现与上限文案不一致，修正边界条件 | 9999（归档：`evidence/regex-limit-9999.txt`）、10000（归档：`evidence/regex-limit-10000.txt`） |
| P2 | 新短结果被原有滚动位置遮住；本轮数字格式和 QR 文本结果也能见到左端裁切 | 问题不限于首轮正则。替换结果时重置/约束滚动和选区，并检查文本容器重绘。完整导出/AX 内容与裁切画面要分开判断 | 本轮截图（归档：`evidence/number-precision-20.png`）、首轮回到起点后（归档：`../evidence/recheck-regex-blank-result.png`） |
| P2 | QR 倍率输入框显示 31，执行值为 30；两份导出 PNG 字节完全一致。格式化缩进 0/9 实际使用 1/8 | 控件限制了值，却没有同步显示。统一输入、步进器和执行值，或直接显示范围错误 | QR 画面（归档：`evidence/qr-scale31-confirm.png`）、[文件核对](verification-readback.json)、缩进 9（归档：`evidence/format-indent-9.txt`） |
| P2 | CSS 视口 20001 得到 200.01px，根/父字号 513 也实际参与计算；步进器显示自身范围内的值 | 这与 QR 的自动限制不同。统一表单范围与引擎契约，不把所有步进器越界都解释成自动限制 | 视口（归档：`evidence/css-height-20001-to-px.txt`）、根字号（归档：`evidence/css-root-513.txt`） |
| P2 | 日期控件显示到秒，但保留隐藏的 305 ms，跨 DST 时间差为 82800.305 秒 | 应展示毫秒或在用户编辑到秒时明确归零，避免不可见输入影响结果 | 记录（归档：`evidence/date-difference-dst.txt`） |
| P2 | UTC 时间戳 -62135596800 显示 0001-01-03，而以延伸公历计算是 0001-01-01；再小 1 秒被拒绝 | 日期范围检查与历史日期格式化的历法口径需要统一。不能把 1970 年后的正常结果推广到整个声明范围 | 最小边界（归档：`evidence/timestamp-bound-min.txt`）、低于边界（归档：`evidence/timestamp-bound-below-min.txt`） |
| P2 | WebSocket 远端正常关闭码 1000 显示“Socket 未连接”错误 | 区分正常关闭、协议错误、TLS 和意外断线；显示 close code/reason | 记录（归档：`evidence/ws-remote-close.txt`） |
| P2 | Mock 空字段名/重名触发内部英文 JSON 解析错误；空字段名后切走回来会提示无法读取字段 | 字段校验错误不应进入 JSON 解析输入；保持可编辑字段状态并定位到错误行 | 空名称（归档：`evidence/mock-empty-field-name.txt`）、重名（归档：`evidence/mock-duplicate-name.txt`） |
| P2 | JWT Header/Payload 为数组仍显示解析完成；URL 解析接受 https://[bad]/ | 补充结构有效性校验。JWT Claims Set 应是 JSON 对象，见 [RFC 7519](https://www.rfc-editor.org/rfc/rfc7519.html#section-2)；解析成功与令牌/网络地址有效应明确分开 | JWT（归档：`evidence/jwt-non-object.txt`）、URL（归档：`evidence/url-parser-brokenhost.txt`） |

首轮“失败仍显示旧字符数、禁用复制但状态计数残留”的问题在本轮错误路径中继续存在，详见首轮截图（归档：`../evidence/recheck-base64-error-footer.png`）。

## 其他可以优化的地方

- 图片压缩可把 70 字节 PNG 变成 777 字节 JPEG，仍显示普通完成。应常驻显示原/目标格式、尺寸、体积、节省比例；体积变大或目标不可达用清楚的提示。体积记录（归档：`evidence/compress-target-max.txt`）
- 对比度 #959595 对白色显示 3.00:1，却判“未达 3”，原因是显示舍入；阈值附近应增加精度或显示“略低于 3”。记录（归档：`evidence/contrast-959595.txt`）
- JPEG/HEIC/PNG、EXIF 旋转和去除自定义元数据均已读回成功；网站图标六张 PNG 与 ICO 均成功，但仍需逐个保存，适合提供批量导出。
- CSS 压缩对不完整 a{color: 输出空文本，HTML 压缩会修复不配对标签。可保留容错能力，同时展示丢弃/修复提示。CSS（归档：`evidence/minify-invalid-CSS.txt`）、HTML（归档：`evidence/minify-invalid-HTML.txt`）
- JWT 正确签名但已过期/未来 nbf 目前主要展示日期和通用提示，建议分别显示“签名有效”“已过期/尚未生效”。未来生效（归档：`evidence/jwt-future-nbf.txt`）
- Cron 的 DST 策略需要明确：纽约春季 02:30 被平移到 03:30；秋季 01:30 只取第一次（UTC−04:00）。日期粘贴对春季不存在时间会拒绝，秋季选择第一次。春季（归档：`evidence/cron-dst-spring.txt`）、秋季（归档：`evidence/cron-dst-fall.txt`）、日期拒绝（归档：`evidence/date-dst-nonexistent-paste.txt`）
- 文本统计的 LF、CRLF 是两行，单 CR、Unicode LS 是一行，应说明或统一换行定义。CR（归档：`evidence/stats-line-CR.txt`）、LS（归档：`evidence/stats-line-LS.txt`）
- QR 2000 字节在 L 级可生成，在 H 级容量不足；应按纠错级别给容量说明。Data URL 的 SVG/损坏图目前共用“尺寸无效或超过 4000 万像素”，建议区分不支持格式、损坏和真正超限。
- 5 MiB+1 字节文本、超像素或损坏图在导入时拒绝，但旧输入保留。需要让失败提示与当前输入来源持续可见，防止再次执行旧样本而误解为超限通过。
- 文件摘要当前 32 MiB 上限阻止处理常见安装包；可改流式读取并显示进度和取消。时区菜单缺搜索、HTTP 通用英文错误及若干原始英文 parser 错误也可以改善。
- 部分 AX 标签仍保留旧标题/数量，截图与结果文本正确。需要独立无障碍/VoiceOver 复核；本报告没有把这些旧 AX 标题当成计算错误。

## 资源、卡顿和取消

设备为 Apple M3 / 16 GiB / macOS 27.0.1，Debug 调试环境。Xcode 的 MB 与 ps 的 RSS MiB 不相加，也不视为相同指标。采样约每 0.5 秒一次，不能捕获所有瞬时峰值。

| 实际负载 | 测得结果 | 解释 |
| --- | --- | --- |
| 5 MiB 文本及连续后续操作 | 补测主进程 RSS 峰值 441.34 MiB，可追踪进程合计 443.19 MiB | 峰值跨越导入、统计及随后切换，不是 abc 摘要自身占用了 441 MiB |
| 4096×4096 图片压缩（首轮） | 527 ms；可追踪进程合计峰值 468.5 MiB | 本次全部已采样负载中的较高峰值，仍是下界 |
| 3000 行源码格式化（首轮） | 1.7 秒 | 可感知等待，未做输入到帧的精确延迟测量 |
| 两侧各 5000 行，全部不同 | 667 ms、5000 新增/5000 删除 | 取消按钮出现后，在点击前完成；不记为取消成功 |
| 2,347,779 字节、3 万函数压缩 | 实际取消，之后小任务成功；阶段合计 RSS 390.84 MiB、CPU 合计峰值 155.1% | CPU 合计可超过一个逻辑核心；并不直接证明主线程阻塞 |
| 极端回溯正则和查找替换 | 均实际取消；首轮 32 个 a 加 ! 的正则等待 1.9 秒 | 未让无界任务一直占用 |
| 接近 5 MiB 的 Data URL 输出 | 5,242,878 字节完整导出，解码与输入相同；5,242,882 字节拒绝 | 结果画面仅展示前 500,000 字符，完整文件读取核对通过 |
| 最后空闲状态 | Xcode Memory 379.4 MB、CPU 0%；RSS 270.09 MiB | 清理了主要大输入与图片，但并非重启后的冷基线；未证明泄漏或完全回收 |

补测两段采样为 01:52:41–03:03:42（7821 条进程记录）及 13:55:23–14:21:40（2984 条）。中间锁屏未连续采样，不做整夜趋势推断。只统计主进程、可追踪 worker/子进程，以及从日志识别且采样时尚存活的部分 WebContent；GPU/Network 和短命 WebContent 可能漏计。第一段实际没有捕获到 WebContent 行，不能称为完整多进程总内存。

阶段标记有些覆盖随后输入准备，例如 stats-line-LS 的高峰包含紧接着的大文件导入，replace-invalid-flags 阶段也含后续替换准备。已在解释中保留这个限制。原始与汇总：第一段 CSV（归档：`process-samples.csv`）、恢复段 CSV（归档：`process-samples-resumed.csv`）、[最终汇总](resource-final-summary.json)、恢复段阶段表（归档：`memory-summary-resumed.csv`）。

## 警告的结论

详细分类、原文和证据见[警告分析](warnings.md)。不能将整批日志统一判成“系统无害警告”。

1. 纯文本基线没有新增该组日志；预览创建会重复产生 WebContent sandbox/XPC/private-resource 诊断。SVG 文本/预览切换 5 轮新增 5 个 WebContent PID；这是可复现的生命周期关联。
2. 同一个现有预览重新执行，先仅截图、再读应用 AX，两次控制台都没有新增警告。因此这个对照不支持“每次读 AX 必然触发”，也尚未排除新建预览时的无障碍影响。
3. 本轮再次看到 AppKit Animation 倒退：14:02:35.448986，约 335.675 ms，位于 ICO 保存面板操作时间段。单独重复 3 次 ICO 保存和打开/保存面板取消未复现，尚无调用栈根因。
4. HTTP/1.0 握手错误来自早期样本服务器，修正为 HTTP/1.1 后连接收发成功；本轮故意触发的超时、不可信证书和关闭日志与未知告警分开记录。
5. PID 608 是 WindowServer。ViewBridge Code 18、无进程来源的 Connection interrupted 仍未精确归因。没有屏蔽日志、关闭 sandbox 或添加系统私有权限。

优先补充 WKNavigationDelegate 的加载失败/内容进程终止记录、可见错误和有限恢复，再评估能否复用受限预览实例及缓存上限。当前证据支持优化创建/销毁频率，不能直接证明每次进程退出都是崩溃。

## 48 个工具的实际覆盖表

以下每行都是已操作内容。完整操作清单见 actions.jsonl（归档：`actions.jsonl`），每条指向实际 UI 证据；expected 字段是操作时的预期，不是自动判定。导航 ID 被重复使用时，证据文件保留最后一次状态，因此条数和唯一 ID 数不同。

| # | 工具 | 已操作子模式 | 已操作边界/结果 | 代表证据 |
| --- | --- | --- | --- | --- |
| 1 | Base64 | 标准/URL Safe × 填充开关 4 组合、两方向 | 缺填充、非法填充、非 UTF-8、空输入；首轮 1 MiB 往返 | 记录（归档：`evidence/base64-empty-decode-corrected.txt`） |
| 2 | URL 编解码 | 参数组件/完整 URL/表单参数 × 编解码 6 组合 | 中文、保留字符、加号、截断百分号、非法 UTF-8、空值 | 记录（归档：`evidence/url-edge-%FF.txt`） |
| 3 | JSON 工作台 | 全部 8 功能；JSONPath/Pointer；结构差异/相同；Schema 成功/失败；类型推断 | 大整数保真、重复键、特殊键、空/坏语法；100/101 层；本地/远程引用 | 记录（归档：`evidence/json-schema-local-ref.txt`） |
| 4 | 哈希摘要 | MD5/SHA-1/SHA-256/SHA-512 × 大小写 8 组合 | abc 标准摘要、空文本 | 记录（归档：`evidence/hash-SHA-512-upper.txt`） |
| 5 | HMAC | 2 算法 × 3 密钥格式 × 2 输出格式 12 组合 | 独立摘要核对；空密钥、奇数 Hex、非法 Base64 | 记录（归档：`evidence/hmac-invalid-base64-key.txt`） |
| 6 | JWT 工作台 | 解析/HS256 验签；正确/错误密钥；none 解析与拒绝验签 | 非法段数/Base64/JSON、数组、空值、过期/未来 nbf | 记录（归档：`evidence/jwt-future-nbf.txt`） |
| 7 | UUID | v4/v7 × 大小写 × 连字符 8 组合 | 0/1/1000/1001；各导出 1000 条，完整核对数量/唯一性/版本位 | 记录（归档：`evidence/uuid-save-v7.txt`） |
| 8 | ULID | 生成、解析 | 0/1/1000/1001；全零、最大合法 128 位、溢出、损坏文本 | 记录（归档：`evidence/ulid-parse-8ZZZ.txt`） |
| 9 | Nano ID | 自定义字母表与数量/长度 | 1/4096/4097；总字符 100000/101000；空/单字符字母表、0 条 | 记录（归档：`evidence/nanoid-alphabet-single.txt`） |
| 10 | 随机字符串 | 排除易混淆字符开/关；自定义 Unicode 字符 | 全部被排除；1/4096/4097 与总量上限；首轮中文/Emoji | 记录（归档：`evidence/random-all-excluded.txt`） |
| 11 | Mock 数据 | JSON/CSV，六种字段类型，种子与数量 | 0/1/10000/10001；种子 0/最大值/负值/越界；空/重复名称 | 记录（归档：`evidence/mock-empty-field-name.txt`） |
| 12 | 正则测试 | 匹配/替换；g/i/m/s/u/v/y/d | 捕获、零宽/Emoji、坏/重复/互斥标志；9999/10000/10001；回溯取消 | 记录（归档：`evidence/regex-unicode-zero-width.txt`） |
| 13 | 文本对比 | 忽略首尾空白开/关；相同/不同；条目/高亮 | 双空值、合计 10000/10001 行、最大合法行数完全不同 | 记录（归档：`evidence/diff-fully-different-after-race.txt`） |
| 14 | 文本统计 | 字符/字素/UTF-16/UTF-8/行等全部输出 | 空值、组合字符、ZWJ、LF/CR/CRLF/LS、5 MiB 和超 1 字节 | 记录（归档：`evidence/text-limit-exact-5m.txt`） |
| 15 | 文本行处理 | 去重/升序/降序/删除空行/行号/前后缀 6 操作 | 重复、空白、中文、真实前后缀、空输入 | 记录（归档：`evidence/lines-affix-actual.txt`） |
| 16 | 命名与大小写 | camel/Pascal/snake/kebab/小写/大写 6 模式 | 英文缩写、混合分隔符、中文 | 记录（归档：`evidence/case-PascalCase.txt`） |
| 17 | 查找替换 | 字面/正则；替换/删除 | 空查找、gi、非法标志、极端回溯实际取消 | 记录（归档：`evidence/replace-backtrack-cancelled.txt`） |
| 18 | Markdown | HTML 文本与受限预览 | 标题/代码/表格；script/iframe/外部图/javascript 链接清理；内联图也被白名单移除 | 记录（归档：`evidence/markdown-sanitize.txt`） |
| 19 | Cron | 当前/指定起点；时区与次数 | 1/100/101；坏字段、无解日期、闰日；纽约春/秋 DST | 记录（归档：`evidence/cron-dst-fall.txt`） |
| 20 | 日期与时区 | 时区转换/日期加减/时间差 | 负天数、跨 DST、隐藏毫秒、不存在时间拒绝、重复时间偏移 | 记录（归档：`evidence/date-dst-ambiguous.txt`） |
| 21 | 时间戳 | 秒/毫秒、时间戳→日期/日期→时间戳、当前时间 | 负值、小数、闰日含毫秒、NaN、0001/9999 与超限 | 记录（归档：`evidence/timestamp-bound-min.txt`） |
| 22 | 进制转换 | 2/8/10/16 的全部 16 方向 | 负数、零、正号、非法数字、空值、1000 位整数 | 记录（归档：`evidence/base-extra-huge.txt`） |
| 23 | 数字格式 | 4 舍入方式 × 正负中点 8 组合；分组开/关 | 38/39 有效位；0/20/21/负小数位；NaN/指数/空；20 位小数精度 | 记录（归档：`evidence/number-precision-20.txt`） |
| 24 | 单位转换 | 大小 7×7、时间 4×4、速率 4×4，共 81 方向 | 零、负值、指数非法、200 位溢出/下溢 | 记录（归档：`evidence/unit-extra-underflow.txt`） |
| 25 | 颜色转换 | HEX 3/4/6/8 位、RGB/RGBA/百分比、HSL/HSLA | 透明度、非法文本、超范围、空值 | 记录（归档：`evidence/color-hsla.txt`） |
| 26 | 颜色对比度 | AA/AAA 普通/大号输出各通过与失败 | 1:1、21:1、3/4.5/7 附近、透明色拒绝 | 记录（归档：`evidence/contrast-959595.txt`） |
| 27 | CSS 单位 | px/rem/em/vw/vh 全部 25 方向 | 基准为零、视口 20001、根/父字号 1/512/513；实际执行值复核 | 记录（归档：`evidence/css-height-20001-to-px.txt`） |
| 28 | URL 解析 | 协议/主机/端口/路径/查询/片段完整输出 | IPv6、重复参数、凭据、空值、无协议、损坏方括号主机 | 记录（归档：`evidence/url-parser-brokenhost.txt`） |
| 29 | 查询参数 | 解析/生成/排序；加号表单语义开/关 | 重复键次序、空值/无值、中文与编码 | 记录（归档：`evidence/query-parse-plus-on.txt`） |
| 30 | Cookie | 请求 Cookie / Set-Cookie | 重复键、值内等号、空值、Expires 逗号、多行头 | 记录（归档：`evidence/cookie-multiple-headers.txt`） |
| 31 | HTTP 状态码 | 1xx/2xx/3xx/4xx/5xx、已知/未知查询 | 100/200/301/404/500/599；99/600/非数字 | 记录（归档：`evidence/http-status-599.txt`） |
| 32 | MIME 类型 | 扩展名/MIME 两种输入 | 带点、PNG/JSON、未知扩展名、空值 | 记录（归档：`evidence/mime-not-a-real-extension-xyz.txt`） |
| 33 | cURL 转换 | fetch / JSON 输出 | 方法/头/中文 body；shell 运算符、@文件引用拒绝 | 记录（归档：`evidence/curl-json.txt`） |
| 34 | 代码格式化 | JS/TS/HTML/CSS；SQL/MySQL/PostgreSQL/SQLite/T-SQL，共 9 路径 | 缩进 1/8/0/9；各语言空/损坏源码；首轮 3000 行负载 | 记录（归档：`evidence/format-invalid-SQL.txt`） |
| 35 | 代码压缩 | JS/CSS/HTML 3 模式 | 字符串与 pre 空白保留；空/损坏源码；2.35 MB 实际取消及恢复 | 记录（归档：`evidence/minify-after-cancel.txt`） |
| 36 | SVG 工作台 | 优化文本/受限预览/导出入口 | 正常图形、script、event、外部引用、实体、损坏/空；预览生命周期与面板取消 | 记录（归档：`evidence/svg-preview-five-recreates.txt`） |
| 37 | 二维码 | 生成/识别；L/M/Q/H 全部生成保存并扫描读回 | 倍率 2/30/1/31；UTF-8 2000/2001；H 容量不足；空、无码、同图双码 | 记录（归档：`evidence/qr-multi-recognize.txt`） |
| 38 | Data URL | 编码/解码；Base64/百分号原始字节 | 大写头、非法百分号/Base64、错误 MIME、SVG/非图；编码后 5 MiB 边界及文件往返 | 记录（归档：`evidence/dataurl-save-near-limit.txt`） |
| 39 | 图片尺寸 | 等比/透明画布/居中裁剪 3 模式 | 1 像素、0、边长超限、2000 万输出像素上下界；导出读回 5000×4000 | 记录（归档：`evidence/resize-20mp-save.txt`） |
| 40 | 图片格式转换 | PNG/JPEG/HEIC 全部保存读回 | 800×400、alpha；质量 1/100/0/101；EXIF 方向路径由图片信息去元数据输出验证 | 记录（归档：`evidence/image-save-HEIC.txt`） |
| 41 | 图片压缩 | 质量/目标大小、有目标/不限、达标/不能达标 | 质量 10/100/9/101；目标 0/1/32000/-1/32001；大图与 1 像素变大 | 记录（归档：`evidence/compress-target-max.txt`） |
| 42 | 图片信息 | 读取/移除元数据并保存再读取 | 4000 万像素允许，超限/损坏拒绝；Orientation 6 转 400×800，描述与方向标记移除 | 记录（归档：`evidence/exif-readback.txt`） |
| 43 | 网站图标 | 16/32/48/180/192/512 PNG 与 ICO，全部预览、保存 | 非正方形透明源图；文件读回尺寸，ICO 三项；重复导出和面板取消 | 记录（归档：`evidence/favicon-save-favicon.ico.txt`） |
| 44 | 文件校验 | MD5/SHA-1/SHA-256/SHA-512；期望匹配/不匹配/大写 | abc/空文件；32 MiB 摘要独立核对；33 MiB 导入拒绝 | 记录（归档：`evidence/file-exact-32m.txt`） |
| 45 | PEM 与证书 | PEM/DER；只解析首张证书 | 指纹一致；损坏/私钥/空拒绝；双证书提示范围 | 记录（归档：`evidence/pem-chain-two.txt`） |
| 46 | DNS 查询 | A/AAAA/CNAME/MX/TXT/NS/SOA/CAA 全部 8 类型 | 系统解析器与本地受控解析器；NXDOMAIN、超时、坏 IP/端口 | 记录（归档：`evidence/dns-CAA.txt`） |
| 47 | HTTP 调试 | GET/POST/PUT/PATCH/DELETE/HEAD/OPTIONS 全部 7 方法；HTTP/HTTPS | 请求头、重定向、404/500、二进制导出、5 MiB/超 1 字节、超时/取消、重复头、方案、TLS 拒绝 | 记录（归档：`evidence/http-response-exact-5m-complete.txt`） |
| 48 | WebSocket 调试 | ws/wss；连接/发文本/收文本二进制/断开/清空重连 | 1 MiB 单条/超限；1000 条/5 MiB 会话；头回显、远端关闭、TLS、坏方案、连接中取消 | 记录（归档：`evidence/ws-send-over-1m.txt`） |

## 文件、证据和验收边界

- [完整文件读回结果](verification-readback.json)：UUID 各 1000 条全部唯一且版本位正确；六张 PNG 尺寸全部正确；ICO 内含 16/32/48；EXIF 清理后 400×800；Data URL 完整字节往返一致。
- 本轮新增样本清单（归档：`fixture-manifest-resumed.json`）、前段样本清单（归档：`fixture-manifest.json`）记录大小与 SHA-256。小文件保存在 fixtures；大文件未重复拷入仓库，[输入生成方式](fixtures/fixture-recipes.md)和导出校验已记录。所有网络/证书/二维码数据为合成样本。多码图片由独立 Core Image 样本脚本创建，实际识别仍在 DevKit UI 中完成。
- 临时网络服务在前段结束时已停止；两个采样器均已停止。保留 Xcode 当前运行的 DevKit，没有停止应用、修改签名、归档或发布。
- 没有执行产品修复或回归测试套件。本报告是已发生的实机操作记录，不是待执行测试用例。
- 未覆盖 Release、Intel、其他 macOS、所有时区/历法、长期稳定性、系统内存压力/OOM、网络丢包分片全组合、Spotlight/签名发布、VoiceOver 全流程和严格帧率测量；这些不能由本次功能覆盖推定通过。
- 曾尝试用浏览器 data: 页面制作多码样本，被浏览器 URL 策略阻止，没有绕过；后来独立生成纯图片样本并在 DevKit 中实际扫描成功。这是样本准备受限，不计为 DevKit 故障。
- 历史锁屏检查点保留在 progress-history.md（归档：`progress-history.md`）。本报告与最终证据优先于早期未完成列表；已拒绝的导入不把随后运行旧输入算作通过。
