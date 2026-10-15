# CLI 与 AI 技能

使用 `devkit` 命令查询工具、处理文件，或接入 AI 技能。

## 安装

![CLI 与 AI 技能安装设置](/images/cli-settings.png)

1. 打开 DevKit「设置 → CLI 与 AI」，点击「安装 CLI」。
2. 安装完成后新开终端，直接使用 `devkit`。已有终端需要重开以读取新配置。
3. 按需点击 Codex 或 Claude Code 的「安装技能」，重新打开 AI 会话后使用 `devkit` 技能。

命令安装到 `~/.local/bin/devkit`，支持为 zsh 和 bash 配置 PATH。移动应用后，在设置中点击「更新链接」。

Codex 技能安装到 `~/.codex/skills/devkit`，Claude Code 使用 `~/.claude/skills/devkit`。其他 AI 可通过「查看技能文件」取得 `SKILL.md`，放入相应目录。

::: details 自定义目录与卸载
配置了绝对路径 `CODEX_HOME` 时，Codex 技能使用该路径下的 `skills` 目录。zsh 的配置位置遵循应用环境中的 `ZDOTDIR`。

卸载时删除设置页显示的 CLI / 技能链接，并移除 Shell 配置中带 DevKit 标记的 PATH 块。
:::

## 发现工具

```sh
devkit list
devkit describe base64
devkit describe json --option operation=query
devkit --help
```

`list` 列出工具，`describe` 显示输入格式、参数和示例。用 `--option` 查看特定操作的参数。

AI 或脚本需要解析结果时，显式选择 JSON：

```sh
devkit list --format json
devkit describe base64 --format json
```

JSON 包含 `protocolVersion: 1`。

## 执行

```sh
printf '%s' 'hello' | devkit run base64 --format text
# 输出 aGVsbG8=，不补换行

devkit run json --input-file ./input.json --option operation=minify
devkit run uuid --text '' --option count=1
devkit run file-checksum --file ./image.png --format text
```

默认从管道读取 UTF-8 文本。`--text`、`--input-file` 和 `--file` 互斥；第二份文本使用 `--secondary` 或 `--secondary-file`。输入保留前后空格与换行。

参数可重复使用 `--option key=value`，也可用 `--options-file options.json` 读取普通 JSON 对象。布尔值必须是 `true` / `false`，整数需符合范围；未知参数、无效枚举和重复参数都会报错。

## AI 结构化请求

复杂输入通过 `devkit run --request request.json --format json`，或通过 stdin 传给 `devkit run --request - --format json`：

```json
{
  "id": "json",
  "input": {"text": "{\"users\":[{\"name\":\"Ada\"}]}"},
  "options": {"operation": "query", "path": "$.users[0].name"}
}
```

`input.text`、`input.secondary` 默认空串；`input.file` 为 Base64，`input.fileName` 是文件名。`options` 是普通 JSON 对象，省略的参数使用工具默认值。完整请求不能与工具 ID、其他输入选项混用，可搭配 `--format` 和 `--allow-network`。

网络工具需要加上 `--allow-network`：

```sh
devkit run http-client --text 'https://example.com' --allow-network
```

令牌和密钥使用 stdin 或请求文件传入，避免写入 Shell 历史。

## 结果与错误

CLI 不会打开或常驻主应用，命令完成后立即退出。单次处理最多运行 25 秒；按 `Ctrl+C`、关闭终端，或结束 CLI 进程时，所属处理进程也会结束。通过管道传入内容时，需要输入端发送 EOF 才会开始处理；等待输入期间也可以取消。

结果写入 stdout，错误写入 stderr。

`--format human` 显式选择默认排版。`--format text` 仅用于 `run`，精确输出 `output.text`，不添加尾部换行，适合管道和重定向保存。

`--format json` 用于 AI 和脚本，成功 JSON 写 stdout：

```json
{"protocolVersion":1,"id":"base64","output":{"text":"aGVsbG8=","rows":[],"artifacts":[]}}
```

JSON 的 `output` 还可能包含 `note`、`report` 和 `html`。附件包含 `name`、`mime`、Base64 `data`，CLI 不自动写文件。

同一 JSON 模式下，失败 JSON 写 stderr，stdout 为空：

```json
{"protocolVersion":1,"error":{"code":"usage","message":"…"}}
```

| 退出码 | 含义 |
| --- | --- |
| 0 | 工具正常返回结果 |
| 1 | 工具执行失败 |
| 2 | 命令参数、请求结构或输入大小错误 |
| 124 | 工作进程超时或资源限制 |
| 130 / 143 | 被 SIGINT / SIGTERM 取消 |

Schema、摘要比较等工具的校验结论在 `output.report.state` 中；HTTP 状态见响应明细。

文本合计上限 5 MiB、二进制输入 32 MiB、主要结果 32 MiB，工作进程有 25 秒墙钟与 15 秒 CPU 上限。部分工具限制更低。CLI 文件校验也受 32 MiB 限制，大文件可使用应用内流式校验。WebSocket 使用一次性连接、发送、接收后关闭，不连接应用中的交互会话。
