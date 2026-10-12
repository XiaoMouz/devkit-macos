# DevKit for macOS

面向 Web 开发者的原生 macOS 工具箱。把编码转换、JSON、文本处理、日期计算、网络调试和图片处理集中在一个工作区。

使用 Swift、SwiftUI 和 AppKit 构建，支持 macOS 26 及以上。当前为 **0.1.0 自用预览版**。

**[下载 v0.1.0](https://github.com/luolayo/devkit-macos/releases/tag/v0.1.0)** · **[在线使用手册](https://luolayo.github.io/devkit-macos/)**

![DevKit JSON 工作台](docs/public/images/json-workspace.png)

## 工具与能力

提供 9 类、48 个工具入口：

| 场景 | 主要工具 |
| --- | --- |
| 编码与数据 | Base64、URL 编解码、Data URL、JSON 工作台 |
| 摘要与令牌 | 哈希、HMAC、文件校验、JWT、证书解析 |
| 生成与文本 | UUID、ULID、Nano ID、Mock 数据、正则、文本对比与统计 |
| 日期与数值 | 时间戳、时区转换、Cron、进制、数字格式与单位换算 |
| Web 与网络 | URL/查询参数、Cookie、HTTP、WebSocket、DNS、cURL 转换 |
| 代码与图形 | 代码格式化与压缩、Markdown、SVG、二维码、图片与网站图标 |
| 前端样式 | 颜色转换、对比度、CSS 单位 |

JSON 的格式化、压缩、校验、路径查询、结构对比、Schema 校验和 TypeScript 类型生成共用一个工作台。

侧栏支持搜索与收藏。切换工具保留当前会话，也可打开独立输入、结果或对照窗口。编辑器提供行号、离线语法高亮和大文本分段编辑；计算、复制和导出使用完整内容。文件校验采用流式读取，支持进度和取消。

文本、数据和图片处理在本机完成；HTTP、WebSocket、DNS 等网络工具由用户主动触发。正文和密钥默认不跨启动保存。

## 安装与运行

从 [Release](https://github.com/luolayo/devkit-macos/releases/tag/v0.1.0) 下载 `DevKit-v0.1.0-macOS-universal.zip`，解压后将 `DevKit.app` 放入「应用程序」。该通用包包含 Apple Silicon 和 Intel 架构，已由 ShenZhen CodeNav Technology Co., Ltd. 进行 Developer ID 签名并通过 Apple 公证。Release 同时提供 SHA-256 校验文件。

从源码运行：

1. 在 Xcode 中打开 `DevKit.xcodeproj`。
2. 选择 **DevKit** scheme 和 **My Mac**。
3. 在 **Signing & Capabilities** 中配置自己的开发团队，按 **⌘R** 运行。

工程使用 Swift 6，Xcode 配置版本为 27.0。机器私有签名配置可放在被 Git 忽略的 `Config/Signing.local.xcconfig`。仓库包含生成的工程和离线解析器资源，普通 Swift 构建无需 Node.js。

归档使用 **Product → Archive**，通过 Xcode Organizer 完成签名与导出。

## 系统快捷入口

Spotlight 集成默认关闭，可在设置中按工具启用。支持命令入口与引导式动作；系统 Quick Key 需要手动配置，有效开发者签名是执行前提。完整系统交互仍需进一步验证。

## CLI 与 AI

在「设置 → CLI 与 AI」安装 `devkit` 命令和配套 Skill，支持 Codex、Claude Code，以及其他支持 `SKILL.md` 的 AI。安装会自动配置终端路径，新开终端即可直接使用命令。CLI 复用 48 个工具核心，默认显示适合阅读的工具列表、参数说明和结果；AI / 脚本可加 `--format json` 获取结构化输出。

```sh
devkit list
devkit describe json
printf '%s' '{"hello":"DevKit"}' | devkit run json --format text
```

安装和调用方式见 [CLI 与 AI 教程](docs/cli-and-ai.md)。

## 开发

核心和会话回归测试使用：

```sh
swift test
```

应用构建、运行和交互验收统一使用 Xcode。JavaScript 资源更新、模块接入与测试说明见[开发维护](.codex/docs/development.md)，功能范围和限制见[实现说明](.codex/docs/implementation-status.md)。

```text
DevKit/                 原生应用、共享界面与系统集成
Sources/DevKitCore/      工具核心、算法与资源
Sources/DevKitWorker/    独立处理进程
Sources/DevKitCLI/       随应用嵌入的命令行入口
Tests/                  核心与会话测试
Vendor/                 离线 JavaScript 依赖与资源构建
.codex/docs/            编码代理共享的项目资料
.claude/CLAUDE.md        Claude Code 项目入口
AGENTS.md               共用开发约定与 Codex 项目入口
docs/                   面向用户的网页教程
```

[在线使用手册](https://luolayo.github.io/devkit-macos/) · [工具参考](docs/tools/index.md) · [项目资料](.codex/docs/README.md)
