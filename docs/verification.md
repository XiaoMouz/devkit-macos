# 0.1.0 验收记录

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
