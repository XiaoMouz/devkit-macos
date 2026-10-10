# DevKit for macOS

使用 Swift / SwiftUI 开发的原生 Web 开发者工具箱，最低 macOS 26。包含 9 类、48 个工具模块，支持搜索、收藏、单工作区与独立窗口、文件导出和系统 Liquid Glass。

JSON 的格式化、查询、对比、Schema 校验和 TypeScript 类型生成共用一个工作台；二维码支持文本生成与选图、拖图或粘贴图片识别。

顶部菜单跟随系统语言，支持简体中文、繁体中文与英文。Data URL 支持图片编码，以及解码后的图片预览、复制和导出。

当前 UI 使用统一透明顶部和侧栏、按场景区分的图片、日期、颜色、数值、参数表单与代码编辑区。Spotlight 设置支持总开关、20 个工具逐项启停、命令别名和索引清理，默认关闭。

当前版本 **0.1.0，自用预览版**。模块均有实际处理逻辑，具体能力和限制见 [实现范围](docs/implementation-status.md)。原设计中的所有进阶选项并非都已覆盖。Spotlight 已实现 App Intents，但系统交互验收仍有阻塞，不能将其视为已完成的发布承诺。

## Xcode 构建、验收与发布

打开 `DevKit.xcodeproj`，选择 `DevKit` scheme 和 `My Mac`：

- 日常验收：按 `⌘R`，使用 Debug 配置运行 Xcode 当前构建的应用。
- 打包发布：选择 `Product → Archive`，使用 Release 配置归档；在 `Window → Organizer → Archives` 中选择归档，再通过 `Distribute App` 完成对应渠道的签名、导出或上传。
- 签名设置：在 Xcode 的 `Signing & Capabilities` 中选择团队；本机配置可保存在已忽略的 `Config/Signing.local.xcconfig`，不由外部脚本重签名。

需要 macOS 26+、Xcode 26+（本次使用 Xcode 27）。仓库已保存生成的工程；修改 `project.yml` 后才需要 XcodeGen 同步工程结构。

交互验收只使用 Xcode 启动的那一份 App。不要并行打开 Applications 安装版、其他构建目录的 App 或另建 UI Review / Layout Check 副本。

Spotlight 系统动作需要有效的开发者团队签名；没有开发签名时，工具箱仍可运行，但不能将其视为已通过 Spotlight 验收。分发渠道及相应签名、公证选项由 Xcode Organizer 管理。

若出现 `Missing package product 'DevKitCore'`，并提示本地包已被另一工程打开，先关闭单独打开的 `Package.swift` / Swift Package 窗口，再只打开 `DevKit.xcodeproj`。

仓库包含本地解析器 bundle；普通 Swift 构建不需要 Node.js，也不联网下载解析器。修改 JavaScript 模块时，需要 Node.js 22+：

```sh
npm ci --prefix Vendor --ignore-scripts
node Vendor/build.mjs
```

## 自动化测试与维护

核心与会话回归测试位于 Swift Package 的 Tests 中，可在 Xcode 中运行，或执行 `swift test`。以下脚本只检查已有产物，不负责构建、安装或发布 App：

```sh
python3 Scripts/integration-tests.py "/path/from/Xcode/DevKit.app"
python3 Scripts/check-spotlight-metadata.py "/path/from/Xcode/DevKit.app"
```

App 路径从 Xcode 的 Products 中定位；发布检查使用 Organizer 中的归档产物。编辑器、外观回归和资源维护说明见 [开发维护](docs/development.md)。

## 工程结构

```text
Sources/DevKitCore/Tools/<tool-id>/   每个工具的参数、元数据和引擎
Sources/DevKitCore/Shared/           编码、图片、网络与类型契约
Sources/DevKitWorker/               可终止的独立处理进程
DevKit/App/                        原生导航、单工作区、菜单、设置
DevKit/Shared/                     编辑器、结果、预览、进程客户端
DevKit/Tools/<tool-id>/             工具专属 UI 或 Spotlight 适配
DevKit/Integrations/Spotlight/      结果卡片、点击复制、快捷动作汇总
Tests/DevKitCoreTests/              核心、格式、媒体与边界测试
Vendor/                            锁定版本的解析器构建与许可证
```

新增模块后运行 `python3 Scripts/update-registry.py` 和 `xcodegen generate`。

- [使用说明](docs/user-guide.md)
- [实现与限制](docs/implementation-status.md)
- [验收记录](docs/verification.md)
- [开发维护](docs/development.md)
- [完整设计文档](docs/README.md)
