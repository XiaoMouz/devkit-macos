# DevKit for macOS

使用 Swift / SwiftUI 开发的原生 Web 开发者工具箱，最低 macOS 26。包含 9 类、72 个工具模块，支持搜索、收藏、单工作区与独立窗口、文件导出和系统 Liquid Glass。

当前 UI 使用统一透明顶部和侧栏、无边框编辑区与右侧配置栏。Spotlight 设置支持总开关、25 个工具逐项启停、命令别名和索引清理，默认关闭。

当前版本 **0.1.0，自用预览版**。模块均有实际处理逻辑，具体能力和限制见 [实现范围](docs/implementation-status.md)。原设计中的所有进阶选项并非都已覆盖。Spotlight 已实现 App Intents，但系统交互验收仍有阻塞，不能将其视为已完成的发布承诺。

## 构建与运行

需要 macOS 26+、Xcode 26+（本次使用 Xcode 27）、XcodeGen 和 Python 3。

```sh
brew install xcodegen
Scripts/build.sh Release
open build/Build/Products/Release/DevKit.app
```

也可以打开 `DevKit.xcodeproj`，运行 `DevKit` scheme。工程由 `project.yml` 生成。

**Spotlight 需要开发者签名。** 本机 macOS 27 的系统日志确认：临时签名缺少 Team ID，动作虽然能被搜索到，系统仍会拒绝执行。构建脚本会使用钥匙串中唯一的有效 Apple 开发签名；无证书时只生成带提示的工具箱预览版，多个证书时要求明确选择。证书准备好后，使用：

```sh
DEVKIT_REQUIRE_SPOTLIGHT=1 Scripts/build.sh Release
# 多个证书时设置 DEVKIT_SIGNING_IDENTITY 为选定证书的 SHA-1
```

在 Xcode → Settings → Accounts 配置开发团队与 Apple Development 证书。本地签名检查只说明运行前提满足，仍需验证系统 Spotlight 的 A/B 流程。

仓库包含本地解析器 bundle；普通 Swift 构建不需要 Node.js，也不联网下载解析器。修改 JavaScript 模块时，需要 Node.js 22+：

```sh
npm ci --prefix Vendor --ignore-scripts
node Vendor/build.mjs
```

## 验证与打包

```sh
swift test
python3 Scripts/integration-tests.py build/Build/Products/Release/DevKit.app/Contents/Helpers/DevKitWorker
Scripts/package.sh
```

产物为 `dist/DevKit-0.1.0-macos.zip`，保留本次构建选择的签名。公众分发前需要开发者自己的 Developer ID 签名、公证和 macOS 26 实机验证。

## 工程结构

```text
Sources/DevKitCore/Tools/<tool-id>/   每个工具的参数、元数据和引擎
Sources/DevKitCore/Shared/           编码、图片、压缩、网络与类型契约
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
