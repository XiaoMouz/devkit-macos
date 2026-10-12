# 版本说明

## v0.1.0

首个预览版本，支持 macOS 26 及以上。[GitHub Release](https://github.com/luolayo/devkit-macos/releases/tag/v0.1.0) 提供 Apple Silicon / Intel 通用包，使用 ShenZhen CodeNav Technology Co., Ltd. 的 Developer ID 签名，已通过 Apple 公证并装订票据，同时提供 SHA-256 校验文件。

- 9 类、48 个工具入口，覆盖编码、数据、摘要、文本、时间、网络、前端样式和图形资源。
- JSON 八种操作统一在一个工作台，支持结构报告与折叠预览。
- 工具搜索与收藏、会话保留、独立窗口、离线语法高亮和大文本分段编辑。
- `devkit` CLI 与 AI Skill，复用同一套工具定义与执行核心。
- 编辑器、侧栏和工具切换性能优化。

### 当前边界

- 主界面以中文为主，完整界面本地化尚未完成。
- Spotlight 默认关闭，完整系统链路仍需进一步验证。
- 连续使用后的应用与辅助进程合计 100 MB 内存目标尚未满足。
- Intel 和最低支持系统的兼容性需要对应实机验证；通用架构构建不等于所有设备已验证。
- 跨启动正文恢复、自动转换、跨工具自动传递和图片批量队列不属于当前功能。

各工具具体支持的格式和限制，请查看[工具参考](tools/index.md)。
