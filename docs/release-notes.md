# 版本说明

## v0.2.0

支持 macOS 26 及以上。[GitHub Release](https://github.com/luolayo/devkit-macos/releases/tag/v0.2.0) 提供 Apple Silicon / Intel 通用包与 SHA-256 校验文件。

- 新增简体中文和英文界面，可跟随系统或在设置中选择语言；窗口与菜单即时更新，保留当前工作和已有结果。
- Spotlight 命令支持中文操作词，命令示例随应用语言切换；英文命令、原有简写和旧版保存的自定义别名继续兼容。
- Spotlight 首次使用、快捷短语和排错说明集中到统一帮助入口。快捷短语由系统 Spotlight 管理，应用内不再提供别名编辑和快捷短语备忘。
- 源码开发使用独立的 DevKit Debug 应用、偏好设置和 Spotlight 索引，避免与正式版冲突。
- 上线中英文使用手册、工具教程和交互式产品演示。

## v0.1.0

支持 macOS 26 及以上。[GitHub Release](https://github.com/luolayo/devkit-macos/releases/tag/v0.1.0) 提供 Apple Silicon / Intel 通用包与 SHA-256 校验文件。

- 9 类、48 个工具入口，覆盖编码、数据、摘要、文本、时间、网络、前端样式和图形资源。
- JSON 八种操作统一在一个工作台，支持结构报告与折叠预览。
- 工具搜索与收藏、会话保留、独立窗口、语法高亮和大文本分段编辑。
- `devkit` 命令行与 Codex / Claude Code Skill。
- 编辑器、侧栏和工具切换性能优化。
