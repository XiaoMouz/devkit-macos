# 技术架构

## 代码层次

| 位置 | 职责 |
| --- | --- |
| `DevKit/App/` | 窗口、导航、设置、命令路由和独立窗口生命周期 |
| `DevKit/Shared/` | 工具会话、编辑器、参数、结果、预览、剪贴板和 worker 客户端 |
| `DevKit/Tools/<id>/` | 工具专属界面及 App Intents 适配 |
| `DevKit/Integrations/Spotlight/` | 系统入口、索引偏好、结果卡片和复制 |
| `Sources/DevKitCore/Tools/<id>/` | 工具元数据、参数、算法和可选 JavaScript 引擎 |
| `Sources/DevKitCore/Shared/` | 处理契约、日期、编码、图像和网络等共享能力 |
| `Sources/DevKitCore/Workspace/` | 布局、参数排列、分页、导航和语法高亮规则 |
| `Sources/DevKitCore/Registry/` | 显式工具注册表 |
| `Sources/DevKitWorker/` | 包内独立处理进程 |
| `Vendor/` | 本地 JavaScript 依赖、打包源与许可证补充 |

`Package.swift` 定义 `DevKitCore`、`DevKitWorker` 和供测试使用的 `DevKitSession`。应用由 Xcode target 编译，并通过工程内的 Embed worker 构建阶段嵌入 helper。不要另建一套应用打包流程。

## 执行与状态

常规工具通过 `ToolSession<T>` 管理输入、参数、版本、结果、取消和错误。执行时冻结请求快照；返回值必须匹配当前版本。`WorkspaceBridge` 传递工具栏动作和轻量呈现状态，不承担业务算法。

主窗口只挂载当前工具，其他工具保留会话数据。`WorkspaceViewState` 与 `EditorViewState` 保存显示模式、编辑器选区、滚动和高亮语言。独立窗口共享业务会话，但拥有自己的呈现状态。窗口快捷键由 `WindowCommandRouter` 按原生窗口分发。

普通处理通过标准输入向包内 worker 发送 JSON，输出结构化结果；输入正文不放进命令行参数。WebSocket 由专用会话处理；原生选择的文件校验采用后台流式读取，避免把整个文件编码进 worker 请求。

## 展示与资源

`CodeEditor` 使用 AppKit 文本编辑，语法着色仅作为临时显示属性。大文本使用受限分页；计算、复制与导出仍使用全文。超长单行采用横向滚动。页面释放时保存必要状态并释放原生文本布局资源。

`SafePreview` 对本地 HTML/SVG 使用受限 WebKit 预览，禁止脚本与外部访问，并处理加载失败和内容进程退出。图片预览使用适合展示的尺寸，导出仍保留结果附件。

布局计算只在实际变化时发布，原生视图更新期间避免回写编辑回调。性能目标与验证方法见[测试要求](acceptance-plan.md)。

## 模块边界

UI、系统动作和测试调用同一工具核心。工具不能访问其他工具的页面状态；通用算法放在共享层。请求、输出、错误和资源上限以 [ToolContract.swift](../../Sources/DevKitCore/Shared/ToolContract.swift) 为准。
