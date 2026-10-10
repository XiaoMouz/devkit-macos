# 0.1.0 验收记录

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
