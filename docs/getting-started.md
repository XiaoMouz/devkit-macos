# 安装与第一步

DevKit 把常见开发工具放进一个原生 Mac 工作区。先从 Base64 或 JSON 开始，熟悉输入、执行和复制，再按任务查阅[工具目录](tools/index.md)。

## 系统要求与下载

- macOS 26 或更新版本。
- 当前版本为 **v0.1.0 预览版**，主界面以中文为主。
- [下载 v0.1.0 通用版 ZIP](https://github.com/luolayo/devkit-macos/releases/download/v0.1.0/DevKit-v0.1.0-macOS-universal.zip)，同时包含 Apple Silicon 和 Intel 架构。
- 安装包由 **ShenZhen CodeNav Technology Co., Ltd.** 进行 Developer ID 签名，已通过 Apple 公证并装订票据。

拿到应用压缩包后，解压并把 `DevKit.app` 放入「应用程序」，再打开它。先固定应用位置，再安装 CLI 和 Skill；这两个入口会链接到应用内的资源。升级时退出应用，替换原位置的应用，重新打开即可。

需要核对下载完整性时，将同一 Release 的 [SHA256SUMS.txt](https://github.com/luolayo/devkit-macos/releases/download/v0.1.0/SHA256SUMS.txt) 与 ZIP 放在同一目录，在该目录运行 `shasum -a 256 -c SHA256SUMS.txt`。

::: info 源码运行
也可下载源码，在 Xcode 打开 `DevKit.xcodeproj`，选择 **DevKit / My Mac**，配置自己的开发团队，按 **⌘R**。归档和导出通过 Xcode 的 **Product → Archive** 与 Organizer 完成。
:::

## 第一次转换

1. 在左侧搜索 `Base64`，选择工具。
2. 点击输入面板的「示例」，得到 `hello`。
3. 顶部选择「编码」，点击右上角「编码」，或按 `⌘Return`。
4. 结果应为 `aGVsbG8=`。点击结果区「复制」取得完整结果。
5. 想还原原文时，选择「解码」，输入 `aGVsbG8=`，再次执行。

![Base64 将 hello 编码为 aGVsbG8=](/images/base64.png)

示例不会自动执行，修改内容也不会在后台自动转换。输入或选项变化后，旧结果会标为「待更新」，重新执行后才能复制或导出。

## 找到常用工具

侧栏可按中文名称、英文 ID、类别或用途搜索。工具栏的星标用于收藏；收藏固定在侧栏上方。切换工具会保留当前窗口的输入、参数和结果。

| 你要做什么 | 从这里开始 |
| --- | --- |
| 格式化、比较或检查 JSON | [JSON 八种操作](guides/json.md) |
| 调试 API、WebSocket 或 DNS | [网络调试](guides/network.md) |
| 改图片尺寸、格式和网站图标 | [图片与网站图标](guides/images.md) |
| 在终端或 AI 中调用工具 | [CLI 与 AI Skill](cli-and-ai.md) |
| 同时查看输入与结果 | [工作区与多窗口](workspace.md) |

## 保存结果与退出

复制和导出都使用完整结果，不受预览截断影响。正文、密钥和工具会话默认只保存在内存中；关闭最后一个关联窗口或退出应用后，先前输入不会自动恢复。需要保留的内容请提前[导出](files.md)。
