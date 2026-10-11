# 0.1.0 验收记录

最新：[2026-10-11 验收修复复验](acceptance/2026-10-11/repairs/report.md)。功能修复和 90 + 15 项 Xcode 回归已完成；使用后 100 MB 内存目标仍未通过。

## 2026-10-11 · 警告归因与全部子模式实操补测

已在用户解锁后完成 [48 工具子模式与极端场景报告](acceptance/2026-10-11/expanded/report.md) 所列范围，保存 768 条操作记录、719 个唯一证据 ID。记录含导航和文件操作，不等于 768 个通过的测试；有问题，不能整体签为全部通过。

- 逐项实际覆盖功能/算法/格式选择：JSON 全8功能、HMAC 12组合、进制16方向、CSS25方向、单位81方向、全部9个格式化语言/方言路径、DNS8类型、HTTP7方法、图像3格式/3尺寸模式、二维码4纠错、Favicon全部产物等；完整明细与错误输入见报告。
- 真实取消、超时/重连、TLS拒绝、数量/字节上限、Unicode、精度、DST、元数据、文件导出读回已执行。源码保持 cafa905，仅使用 Xcode 当前 Run 实例 PID 47490，未修改产品代码。
- 新增确认数字格式20位小数精度损失、正则10000匹配边界、多行Set-Cookie合并、参数显示与执行值不一致、隐藏毫秒、历史日期历法口径差异、正常WebSocket关闭显示错误等；优化项与优先级见报告。
- 最后清理主要大样本后 Xcode Memory 379.4 MB、CPU 0%，主进程 RSS 270.09 MiB；仍未达到使用后100 MB目标，尚无堆证据认定泄漏。全部采样和口径限制已封存。
- [警告分析](acceptance/2026-10-11/expanded/warnings.md)记录了预览切换新增WebContent进程和重复诊断；AppKit动画倒退再次出现于ICO保存时段，独立重复未复现，根因未定。未屏蔽日志或降低系统保护。
- 临时网络服务、采样器均已停止，Xcode中的DevKit保留运行。Release/其他系统/长期稳定性/严格帧率和堆归因未覆盖，不推定通过。

## 2026-10-11 · 48 个工具真实桌面操作验收

完整记录见 [48 个工具实机操作验收报告](acceptance/2026-10-11/report.md)，包含逐项操作、输入与结果、截图、文件导出回读、原始进程采样与优化建议。本轮没有运行单元测试来代替 UI 操作，也没有修改产品源码。

- 使用 Xcode 已运行的 `DevKit / My Mac` Debug 实例（PID 47490），仓库提交 `cafa905`；48/48 个工具均实际打开并执行，覆盖范围以报告各行记录为准，不代表全部子模式已经通过。
- 核对文本转换、摘要、生成器、JSON、日期数值、样式、文件/图片、DNS、HTTP 和 WebSocket。二维码完成生成、保存、重新导入与识别；HTTP 实际验证 GET、POST、取消和响应上限；WebSocket 实际验证收发、切换后继续收发和断开。
- Xcode 主进程 Memory 初始 87.5 MB，前 19 个工具后 129.5 MB，大文本/JSON 后 241.9 MB，清理大输入后仍为 228.6 MB、CPU 0%。使用后 100 MB 目标未达到，尚不能仅凭这些读数认定内存泄漏。
- 4096×4096 图片压缩阶段，可追踪主进程与 worker 的采样 RSS 合计峰值 468.5 MiB；此指标不包含全部独立 WebKit 进程，与 Xcode Memory 不同。回溯正则耗时 1.9 秒、3000 行 JavaScript 格式化 1.7 秒、1 MiB Base64 解码 1.1 秒。
- 已记录短结果可视区域空白、失败状态显示旧结果计数、图片结果缺少直接可见的尺寸/体积信息等问题。重复结果的 AX 旧值与实际截图不一致，单列为待确认项，不误报为算法错误。

## 2026-10-10 发布也统一到 Xcode

- 按用户要求，构建、运行、签名、Archive 与分发全部由 Xcode 处理：Run 使用 Debug，Archive 使用 Release，在 Organizer 中选择分发渠道并签名、导出或上传。
- 移除 8 个外置流程脚本：构建、打包、重签名、签名策略测试、旧版注册清理、流程辅助测试、Xcode 产物定位和图标批量导出。保留回归测试、注册表及离线资源维护工具。
- 集成测试显式接收 Xcode 生成的 DevKit.app 路径，不再导入已删除的路径定位模块。对当前 Xcode Debug helper 的 12 项集成测试通过。
- 已检查共享 scheme：Run = Debug、Archive = Release、归档后显示 Organizer；worker 的 SKIP_INSTALL 配置和嵌入构建阶段保留。剩余 Python 脚本语法检查、测试 CLI 帮助检查通过。
- README、项目约定及开发/验收文档同步更新。本轮只调整流程，没有执行归档上传或公开发布。

下文中的旧脚本和旧打包命令是历史验收记录，不再作为当前操作说明。

## 2026-10-10 验收统一到 Xcode Run

- 用户明确指定以 Xcode 为唯一验收入口。原生 Xcode 窗口确认：工程 `DevKit.xcodeproj`、scheme `DevKit`、目标 `My Mac`，状态 `Running DevKit`。
- `Scripts/xcode_app.py` 解析 Debug 构建设置，与正在运行的 DerivedData App 路径一致；本轮保留该进程，没有重启或替换正在验收的产物。
- `/Applications/DevKit.app`、项目 `build/Build/Products/Debug/DevKit.app` 和 `Release/DevKit.app` 三份旧副本已做逐文件校验的 ZIP 备份并移除。废纸篓旧包仅注销注册，文件保留。
- 最终 Launch Services 只剩 Xcode DerivedData 下的 Debug App，进程列表只有同一路径的一份 DevKit，归档清理 dry-run 无待清理项。
- 默认构建脚本使用 Xcode 默认 DerivedData，不再生成项目内第二套验收 App；集成测试默认定位同一 Debug helper。Release 打包使用临时目录并在退出时移除临时 App，仅保留 ZIP。
- `AGENTS.md`、README 和开发/验收文档写明统一入口，后续 UI 验收不再创建独立身份的预览副本。
- 8 项流程回归检查和两份 shell 脚本语法检查通过。本轮没有执行 Release 打包，也没有为脚本调整重复运行应用功能测试。

## 2026-10-10 场景输入与 JSON 合并

- 当前 48 个工具入口；原 JSON、JSON 路径、JSON 结构对比、JSON Schema、TypeScript 类型五个入口合并为 JSON 工作台，原有处理能力保留。
- `swift test`：51 项核心测试、11 项共享会话测试通过。覆盖统一 JSON 的八种操作、四种二维码纠错级别的生成/识别往返、重复参数和特殊字符、上下文示例、单位换算类别、导入类型、模式切换保留内容、HTTP 正文优先展示及 Base64 文件往返。
- 最终 Release 构建和开发者签名验证通过。打包内 worker 的 12 项集成测试通过，包含 JSON 八种操作、二维码图片往返、HTTP 正文与正确文件格式导出；App Intents 元数据检查通过。
- 原生 UI 逐项检查全部 48 个入口的输入控件。实测 JSON 工作台生成 TypeScript；二维码生成、复制图片、粘贴到识别模式并还原网址；完整 URL 转参数行、重复键编辑、中文和保留字符编码。
- 参数按当前操作显示；图片/文件、生成器、数值、日期、颜色、参数行使用对应控件。代码和文本处理保留编辑器。图片缩放默认保持比例，元数据默认展示关键信息，二进制结果以文件形式保存，HTTP 响应正文直接可见。
- 本轮未对公网发请求；网络执行回归使用本机临时服务。既有 Spotlight 系统执行链路限制见下方历史记录。

## 2026-10-10 功能精简与 Data URL 修复

- 工具从 72 个精简到 52 个；Spotlight 可配置工具从 25 个减到 20 个，移除清单见 [工具目录](tool-catalog.md)。
- `swift test` 通过：44 项核心测试、5 项共享会话测试。新增 PNG/JPEG/HEIC 字节不变的图片往返、百分号载荷、非图片/损坏载荷/错误 MIME 拒绝，以及切换模式的会话状态测试。
- Debug 和最终 Release 构建通过；Release 使用现有开发者证书签名。
- 最终 Release worker 的 10 项集成测试通过，包含图片 Data URL 往返及全部 20 个已移除工具的执行入口检查。
- App Intents 元数据检查通过：4 个公开后台动作及其参数、App Shortcuts 配置正常；这不替代 Spotlight 系统执行链路验收。
- 实际 UI 验证：简体中文显示“文件 / 编辑 / 显示 / 工具 / 窗口 / 帮助”；英文显示“File / Edit / View / Tools / Window / Help”，Tools 子菜单翻译完整。最终 Release 在系统语言下启动为中文。
- 实际 UI 完成选图、编码、切换解码、粘贴 Data URL、执行、图片预览与保存；导出 PNG 与原始图片逐字节一致。设置通用页仅保留外观和编辑器选项。

以下为此前版本的历史验收记录；工具数量和能力以本轮记录及当前目录为准。

日期：2026-10-09（Asia/Shanghai）。环境：Apple M3、16 GiB RAM、macOS 27.0.1（26A434）、Xcode 27.0（27A266a）、Swift 6.4。最低部署目标 26.0；本记录不等于在 macOS 26 或 Intel 上通过。

## 已执行

| 检查 | 实际结果 |
| --- | --- |
| Swift 核心测试 | `swift test`，30 项、4 个 suite 通过；含文本工具的内置样例遍历 |
| 集成测试 | `Scripts/integration-tests.py`，8 项通过；使用本机临时 HTTP、WebSocket 和 DNS 服务，不依赖公网 |
| Xcode 构建 | Debug 与 Release 构建成功；最终应用和 helper 含 arm64 / x86_64，仅 arm64 实机运行 |
| 模块注册 | 72 个独立工具 ID，注册唯一性检查通过 |
| 系统动作元数据 | 应用包含 32 项 App Intents 元数据（30 个公开动作、2 个内部结果/复制动作），10 个 App Shortcuts |
| 本机签名 | 应用与 helper 临时签名；`codesign --verify --deep --strict` 检查通过 |
| 安装 | 干净替换到 `~/Applications/DevKit.app` 并成功启动；未向公众发布 |
| ZIP | `dist/DevKit-0.1.0-macos.zip`，Release 应用包 |

核心测试覆盖 Base64 标准向量、未填充解码、非法字符/填充、中文和二进制、命令原文、MD5/SHA/HMAC 向量、UUID/ULID、随机字符约束、JSON 大整数与长小数、Schema 路径错误、CSV 引号和换行、Pointer、Unicode 代理对、XML 实体拒绝、Markdown/SVG 安全边界、静态 cURL、正则捕获、固定时区 Cron、压缩往返/损坏流、颜色/对比度、Decimal、URL 表单、图片尺寸/格式/信息/ICO、QR 往返、Basic Auth、JWT 验签与算法拒绝、证书及文件摘要。

集成测试覆盖 HTTP GET、POST 尾部换行、5 MiB 响应限制、WebSocket 中文和换行回显、DNS 自定义本地解析器、未知工具错误、高回溯输入的有界执行，以及终止工作进程。JavaScriptCore 可以优化掉部分高回溯样例，因此该项不宣称每次都会触发系统硬超时。

## 真实界面记录

使用实际安装的应用与原生 UI 自动化操作，已观察到：

- `hello` 通过执行按钮和 `⌘Return` 得到 `aGVsbG8=`。
- 原生编辑器为第一响应者时，窗口级命令分发可正常执行；先发现再修复了焦点导致快捷键失效的问题。
- 用户提供的 `MTIzMTIzMTIzYXNkZmFkc2ZzZGFmCg` 解码为 `123123123asdfadsfsdaf` 加一个 LF，结果显示 **22 字节** 和尾部换行标识。
- 点击解码结果卡片显示“已复制完整结果”；复制发生在点击后。
- JSON 样例中的 `9007199254740993` 在输入与格式化结果中保持一致。
- 修改 JSON 输入后，原结果显示“待更新”，复制与导出禁用。
- 切换标签保留 Base64 的输入、结果与复制状态；`⌘1` 和 `⌘W` 正常切换/关闭标签。
- `⌘⌥F` 聚焦搜索，输入 `websocket` 只显示对应工具。
- WebSocket 专属视图连接本机服务，发送 `hello 你好` 加 LF，展示发送和接收两条消息；断开和关闭标签成功。
- 首轮只观察了默认尺寸；此前未覆盖的联动和布局缺陷已进入 [本轮 UI 修正记录](ui-refinement.md)，不据首轮截图宣称所有布局正常。

调试版本的单次界面样例：Base64 约 75 ms、JSON 约 209 ms；最终 Release 中 Base64 约 72 ms。进程 RSS 单次观察约 105 MiB（无活跃 helper）。这些是本机小样本，不是冷启动、峰值内存或所有大小输入的性能保证。

## Spotlight 阻塞

本机系统 Spotlight 当时未运行。通过系统快捷键与 Spotlight 应用入口尝试启动，系统返回 `RBSRequestErrorDomain Code=5`、底层 `NSPOSIXErrorDomain Code=162`（Launchd job spawn failed）。系统菜单服务入口也未取得可操作窗口。没有更改或重置用户的系统 Spotlight 设置。

因此以下事项仍为**未验收**：

- 在 Spotlight 搜索并发现动作；引导式 A 的选择、输入、执行和复制。
- `base64` Quick Key 是否允许完整字母/数字关键词，以及命令式 B 的尾部文本传递。
- A/B 裸关键词冲突、前后空格/Unicode/换行保真、后台冷启动、不抢主窗口、系统结果卡片点击复制。
- macOS 26、系统不同语言、安装后升级、系统索引变化的行为。

构建、元数据和核心解析测试不替代这些实机项目。应用未增加自定义全局启动器来冒充系统 Spotlight。

## 后续发布验收

仍需要 macOS 26 实机、Intel（若决定支持）、VoiceOver、浅色/不同强调色、减少透明度/动态效果、多个窗口尺寸和多显示器的完整矩阵。原设计中的高级功能差距见 [实现范围](implementation-status.md)。正式 Developer ID 签名、公证和公开分发尚未执行。

## 2026-10-10 · UI 与 Spotlight 配置更新

环境：macOS 27.0.1（26A434）、Xcode 27 / Swift 6.4；目标仍为 macOS 26。

- Swift 测试通过：Core 46 项、Session 4 项，共 50 项。新增 8 项 Spotlight 命令测试覆盖默认关闭、单工具开关、别名冲突、原文与 Unicode 保留、空输入、缺省填充、生成数量与损坏配置。
- 打包 worker 的 8 项集成测试通过，包括本地 HTTP、WebSocket、超时与取消边界。
- Release 构建与应用深度签名校验通过。安装包输出到 `dist/DevKit-0.1.0-macos.zip`。
- 真实窗口检查：顶部/左侧连贯背景，无上下横线或底栏；右侧无嵌套编辑卡片；输入/结果/对照与操作集中在顶部；Base64 `hello → aGVsbG8=`、长文本切换、配置收放、UUID 参数列表、独立结果窗口及深浅色切换正常。
- Spotlight 设置实测：总开关、Base64 单工具索引同步、别名冲突提示、清空并关闭均通过。最后恢复总开关及所有工具关闭；设置显示“DevKit 工具索引已清空，快捷执行已关闭”。
- 元数据检查：仅 `DevKitCommandIntent`、`DevKitToolIntent` 两个公开动作，2 个 App Shortcuts；30 个旧动作停止公开发现，另有 2 个内部结果动作。
- 注销项目中旧构建及预览副本的 Launch Services 注册。清理脚本只针对 `app.devkit.macos` / `app.devkit.preview` 在本项目内的路径，默认保留正式安装副本；未重建或删除系统级 Spotlight 数据库。
- 仍未验收：系统 Spotlight 应用启动返回 Launchd job spawn failed（162），因此 Quick Key 参数采集和系统结果卡片的完整交互无法在本机确认。macOS 26 基线实机也仍需检查。


## 2026-10-10 Spotlight 独立入口修复

- 恢复公开的 Base64 命令与引导动作，补齐搜索关键词，并将系统快捷短语绑定说明提前到设置页。
- 构建号 2 的 Release 构建通过；编译元数据确认四个可发现的后台动作和完整参数摘要，校验脚本为 `Scripts/check-spotlight-metadata.py`。
- `swift test`：48 项 Core 与 4 项 Session 测试通过。新增覆盖 Quick Key 后的参数、完整命令、用户别名、大小写和 enc/dec、空白与换行保留、缺少参数、超限、开关拦截和跨工具输入拒绝。
- 用户明确选择自行验证 Spotlight。尚不将系统内搜索、Quick Key 参数传递、结果卡片和点击复制标记为验收通过。


## 2026-10-10 系统调用失败的根因

用户已能在 Spotlight 发现并选中“Base64 命令”，但运行提示“快捷指令无法与 App 通信”。本机日志证据：

```text
linkd: Unable to get teamId from app.devkit.macos PID [33396]
linkd: Rejecting invalid client due to requiresValidatedBundle
linkd: LNConnectionErrorDomain Code=1200 / AppleEvents communication failed
```

`codesign -dvv` 显示 Signature=adhoc、TeamIdentifier=not set；`security find-identity -v -p codesigning` 返回 0 valid identities。修正构建脚本，增加运行签名诊断与四项签名策略测试；强制 Spotlight 模式已验证会因缺少证书而提前失败。

A/B 体验定义不变，当前系统端执行尚未通过。下一步必须先由用户准备有效 Apple 开发签名，再构建安装并验证执行与复制；不再让临时签名包进入同样的无效重试。


## 2026-10-10 开发者签名后的通信验证

- 用户已创建 Apple Development 证书与私钥。最初能枚举签名身份但有效身份为 0；检查发现缺少 WWDR G3 中间证书，钥匙串只有旧版过期 WWDR。补齐 Apple PKI 官方 G3 中间证书前先验证其 Apple 信任链，未添加自定义根信任或更改证书信任策略；之后有效身份为 1。
- 使用 `DEVKIT_REQUIRE_SPOTLIGHT=1 Scripts/build.sh Release` 成功构建并签名。应用与 worker 的开发者 TeamIdentifier 一致，深度签名校验通过。安装版 worker 的编码、解码、缺少填充且保留尾部换行三项检查通过。
- 安装后 `linkd` 对 `app.devkit.macos` 的 `autoShortcut` 和 `mediator` 连接均记录 `Accepting`；应用日志记录 `Registered process`，系统收到新的 AppShortcut 参数。该次启动的注册/连接错误为 0，之前的缺少 Team ID 拒绝已排除。
- 通信与注册阶段已通过；系统 Spotlight 中 A/B 的完整输入、结果和点击复制仍由用户自行验证，不能将本条记录等同于完整交互验收。

## 2026-10-11 工具切换与常驻内存优化

通过 `DevKit.xcodeproj` 的 `DevKit / My Mac` 在 Xcode 中 Run / Debug 构建与交互验证，未生成或启动独立预览 App，未修改签名配置。

- 主窗口只挂载当前工具，后台保留输入、参数、结果和轻量显示状态；编辑器选区、滚动位置和高亮语言通过状态对象保存。WebSocket 连接跟随会话关闭，不因临时切换页面被断开。
- 菜单快捷键统一通过原生窗口路由，合并焦点通知并在当前视图更新结束后通知菜单；去掉重复的 FocusedValue 发布。布局计算只发布实际变化，原生编辑器更新期间不回写编辑回调。
- 时区菜单按需创建原生菜单项，保留常用/所有时区与参数回写。Cron 使用当前时间时不创建日期编辑器，取消勾选后才加载原生日期控件。内容区按钮使用轻量原生样式，避免对多个玻璃候选布局反复测量。
- Spotlight 关闭并已成功清理索引时，后续启动跳过重复 XPC 清理、签名查询与快捷指令注册；开启后保留原索引同步和签名检查。

本机 macOS 27.0.1、Apple Silicon、Xcode Debug 的观察样本：

| 场景 | Xcode Memory |
| --- | --- |
| 优化前已经使用多个工具 | 约 275–287 MB |
| 优化后启动（不同轮次与窗口激活状态） | 约 77–93 MB |
| Cron 示例、切换时区、打开并关闭独立结果窗口后 | 约 118 MB |
| 随后在 Base64、时间戳、Cron 间连续切换 8 次 | 约 110 MB |

这是开发机上的交互样本，前后并非严格一致的输入与操作序列，不作为全功能峰值或 Release 基准。启动达到 100 MB 内目标，使用后的常驻占用仍未达到该目标。

Xcode 执行会话测试 13 项全部通过；核心测试 74 项全部通过（含动态参数共 79 次执行）。新增回归验证相同布局不重复触发 Observation 更新。实机验证 Base64 输入/结果切换后保留、Cron 执行快捷键、UTC 时区回写与计算、独立结果窗口的共享结果与快捷键、当前时间/指定日期模式切换，以及连续切换。最后一次堆快照（Cron 页面）未发现驻留的 WorkspaceTextView 实例，先前文本工具的编辑器已释放。

上述实测路径未再出现 `FocusedValue update`、`glassEffect() tried to update`、`Cycle detected through attribute`、`DetachedSignatures` 和 `NSSecureCoding allowed classes` 日志。`Unable to obtain a task name port right for pid 608` 在执行工具时仍偶发；本机该 PID 是系统 WindowServer，尚未定位其系统调用来源，不宣称所有系统诊断均已消除。未设置日志屏蔽或关闭系统安全检查。
