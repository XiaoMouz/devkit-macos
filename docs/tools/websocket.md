# WebSocket 调试

连接 WebSocket 服务，发送消息并查看收发记录。

CLI：`websocket`

## 使用方法

输入 ws:// 或 wss:// 地址并连接，在消息输入区编辑后手动发送。右侧逐条查看收发记录；点击记录可复制，完成后断开连接。

连接状态和消息记录属于当前 WebSocket 会话，关闭会话会断开连接。

## 示例

输入：

```text
wss://echo.websocket.org
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `message` | 发送文本 | `hello DevKit` | 文本 |
| `count` | 接收消息数 | `1` | 1–100 |

## CLI 调用

```sh
devkit describe websocket
```

从文件读取：

```sh
devkit run websocket --input-file ./input.txt --allow-network
```

CLI 使用一次性调用，不共享窗口中的连接。可通过 `message` 和 `count` 设置发送内容和接收条数。

## 注意事项

会话上限为 1000 条 / 5 MiB，单条消息上限 1 MiB。关闭会话后记录不再保留。
