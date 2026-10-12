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
| `Sources/DevKitCLI/` | 包内 `devkit` 命令与 worker 进程桥接 |
| `Sources/DevKitCore/Automation/` | CLI 参数校验、工具发现、JSON 协议与安装链接 |
| `Vendor/` | 本地 JavaScript 依赖、打包源与许可证补充 |

`Package.swift` 定义 `DevKitCore`、`DevKitWorker`、`DevKitCLI` 和供测试使用的 `DevKitSession`。应用由 Xcode target 编译，并通过工程内的 Embed command-line helpers 构建阶段将 worker 和 CLI 嵌入 `Contents/Helpers`。不要另建一套应用打包流程。

CLI 的 `list` / `describe` 从 `ToolRegistry` 和 `OptionField` 生成描述，`run` 校验参数后调用同一包内 worker。选项按字段定义顺序写入，保留关联参数的默认值行为。CLI 与 UI 会话、剪贴板独立；`CommandPresentation` 负责默认的人类可读分组与排版，AI 显式使用 `--format json` 取得带 `protocolVersion` 的协议结果。错误遵循所选格式，写 stderr 并使用非零退出码；`run --format text` 保留精确原文。默认格式不依据 TTY 或管道自动切换。Skill 原文位于 `Sources/DevKitCore/Resources/Skills/devkit`，通过 Swift Package 资源一起分发。设置页创建 CLI / Skill 用户目录链接，不复制应用、不覆盖未知同名文件；CLI 安装时为当前登录 Shell 的启动配置追加幂等 PATH 块，支持 zsh 和 bash，保留用户原有配置。

## 执行与状态

常规工具通过 `ToolSession<T>` 管理输入、参数、版本、结果、取消和错误。执行时冻结请求快照；返回值必须匹配当前版本。`WorkspaceBridge` 传递工具栏动作和轻量呈现状态，不承担业务算法。

主窗口只挂载当前工具，其他工具保留会话数据。`WorkspaceViewState` 与 `EditorViewState` 保存显示模式、编辑器选区、滚动和高亮语言。独立窗口共享业务会话，但拥有自己的呈现状态。窗口快捷键由 `WindowCommandRouter` 按原生窗口分发。

侧栏搜索和分类展开状态由 `ToolSidebar` 持有，输入搜索词不触发主工作区重建。工具目录、ID 映射和分类分组在窗口间复用静态元数据。

普通处理通过标准输入向包内 worker 发送 JSON，输出结构化结果；输入正文不放进命令行参数。WebSocket 由专用会话处理；原生选择的文件校验采用后台流式读取，避免把整个文件编码进 worker 请求。

## 展示与资源

`CodeEditor` 使用 AppKit 文本编辑，语法着色仅作为临时显示属性。大文本使用受限分页；计算、复制与导出仍使用全文。超长单行采用横向滚动。页面释放时保存必要状态并释放原生文本布局资源。

每次原生文本变更生成一次连续 UTF-8 的 Swift 快照，绑定和高亮共用，避免对 AppKit 的外部字符串存储重复做 Unicode 比较和计数。编辑器按文本内容缓存字符数及换行判断，状态和窗口刷新不重复扫描全文；同步与缓存比较保留原始字节差异。行号和长行检测使用 Foundation 换行边界，覆盖 CRLF 和 Unicode 换行符。原生可编辑状态、滚动条和换行布局仅在对应配置变化时更新。

`SafePreview` 对本地 HTML/SVG 使用受限 WebKit 预览，禁止脚本与外部访问，并处理加载失败和内容进程退出。图片预览使用适合展示的尺寸，导出仍保留结果附件。

布局计算只在实际变化时发布，原生视图更新期间避免回写编辑回调。性能目标与验证方法见[测试要求](acceptance-plan.md)。

## 多语言

`Shared/Localization.swift` 从 Swift Package 的 `Resources/Translations/*.json` 读取语言、显示名称与文案。Swift UI、核心和 JavaScript 引擎共用资源；`Scripts/localization.py` 同步原生菜单与 App Intents 的 string catalogs。英文为源语言和翻译键，`LanguageSelection` 通过 Observation 让界面实时更新，保留会话与已有结果；执行开始时冻结工作进程语言。新增语言只涉及翻译资源，具体贡献方式、回退与 worker 传递规则见[多语言规范](localization.md)。

## 模块边界

UI、系统动作和测试调用同一工具核心。工具不能访问其他工具的页面状态；通用算法放在共享层。请求、输出、错误和资源上限以 [ToolContract.swift](../../Sources/DevKitCore/Shared/ToolContract.swift) 为准。
