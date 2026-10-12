# 安装与第一步

## 安装

需要 macOS 26 或更新版本。

1. 从 [Releases](https://github.com/luolayo/devkit-macos/releases/latest) 下载应用压缩包。
2. 解压后将 `DevKit.app` 放入「应用程序」，双击打开。
3. 如需使用命令行，在「设置 → CLI 与 AI」中安装，见 [CLI 教程](cli-and-ai.md)。

升级时退出应用，用下载的新版本替换原位置的应用。

应用默认跟随系统语言。需要切换英文或简体中文时，见[选择语言](shortcuts.md#选择语言)。

## 第一次转换

1. 在左侧搜索 `Base64`，选择工具。
2. 点击输入面板的「示例」，得到 `hello`。
3. 顶部选择「编码」，点击右上角「编码」，或按 `⌘Return`。
4. 结果应为 `aGVsbG8=`。点击结果区「复制」取得完整结果。
5. 想还原原文时，选择「解码」，输入 `aGVsbG8=`，再次执行。

![Base64 将 hello 编码为 aGVsbG8=](/images/base64.png)

修改输入或选项后，点击顶部主按钮重新执行。

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

需要保留的内容请在退出前[导出](files.md)。应用不会在下次启动时恢复输入和结果。
