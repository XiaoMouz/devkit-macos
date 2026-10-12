# DevKit 的 Xcode 工作流

- 用户指定：构建、交互验收、签名、归档和发布都统一使用 Xcode。打开 `DevKit.xcodeproj`，选择 `DevKit` scheme 和 `My Mac`。
- Debug 使用应用名 `DevKit Debug` 和 Bundle ID `app.devkit.macos.debug`；Release 使用 `DevKit` 和 `app.devkit.macos`。保持两者的系统注册、Spotlight 索引和偏好独立，签名团队仍由现有本机配置维护。
- 日常验收使用 `⌘R`（Run / Debug），只操作 Xcode 当前启动的这一份应用。不要安装或直接打开另一份 Debug/Release App，不复制 UI Review / Layout Check 等独立 bundle ID 的预览应用。
- 打包发布使用 `Product → Archive`（Release），在 `Window → Organizer → Archives` 中通过 `Distribute App` 选择分发渠道并完成签名、导出或上传。只有用户明确要求实际发布时才执行上传。
- 不要重新添加独立的构建、打包、重签名、安装、启动、产物定位或注册清理脚本。不要用命令行生成另一套 App 作为验收版本。
- 签名在 Xcode 的 Signing & Capabilities / 本机 xcconfig 中维护。不要覆盖用户现有的团队、证书或其他未提交配置。
- `Scripts/` 只保留测试和源码/资源维护工具；这些工具不能安装或启动另一份 DevKit。集成测试与 Spotlight 元数据检查显式接收从 Xcode 取得的 App 路径，不自行构建或猜测产物目录。
- `project.yml` 用于维护生成的工程结构；仅在需要同步工程配置时使用 XcodeGen，避免覆盖他人的未提交工程改动。新增模块时更新注册表，JavaScript 引擎变更时更新 Vendor bundle。

## 项目资料与文档维护

- 编码代理的共享资料位于 [.codex/docs/README.md](.codex/docs/README.md)，按任务选择相关主题；无需为普通小改动读取全部文档。
- Claude Code 通过 `.claude/CLAUDE.md` 导入本文件，共用同一份约定与资料。
- `.codex/docs/` 只维护当前架构、开发约束、功能边界和测试要求，不追加按日期组织的工作日记、验收流水、测试次数或本机调试记录。
- `docs/` 专用于面向用户的网页教程；根目录 `README.md` 负责产品介绍、运行入口和文档导航。
- 代码或行为改变时更新对应主题，替换失效内容；变更历史留在 Git，临时报告和证据放在已忽略的 `build/` 或仓库外。
