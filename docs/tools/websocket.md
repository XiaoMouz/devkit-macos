# WebSocket 调试

手动连接、发送与接收，断开后不保存会话。

类别：Web 与网络 · CLI ID：`websocket` · 主动执行时联网

## 怎么用

输入 ws:// 或 wss:// 地址并连接，在消息输入区编辑后手动发送。右侧逐条查看收发记录；点击记录可复制，完成后断开连接。

连接状态和消息记录属于当前 WebSocket 会话，关闭会话会断开连接。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
wss://echo.websocket.org
```

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `message` | 发送文本 | `hello DevKit` | 文本 |
| `count` | 接收消息数 | `1` | 1–100 |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe websocket
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run websocket --input-file ./input.txt --allow-network
```

CLI 使用一次性调用，不共享窗口中的连接。可通过 `message` 和 `count` 设置发送内容和接收条数。

## 边界与注意事项

专属界面手动连接/发送/接收/断开；1000 条/5 MiB；不持久化。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
