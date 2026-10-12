# 数据保存

## 工具会话

切换工具会保留当前窗口的输入、参数和结果。独立窗口与来源工具共享内容，关闭最后一个关联窗口或退出应用后，会话结束。

需要保留的结果请提前[导出](files.md)。收藏、外观和工具开关会自动保存。

## 文件

导入文件后，处理结果通过「导出…」另存。保存时可以选择文件名和位置。

CLI 使用 `--format text` 输出文本，配合重定向保存到文件：

```sh
devkit run json --input-file input.json --format text > output.json
```

## 网络请求

HTTP 和 DNS 在点击执行后发送请求，WebSocket 在连接后收发消息。CLI 调用网络工具需要 `--allow-network`，详见[网络调试](guides/network.md)。

## 令牌与密钥

在命令行处理令牌或密钥时，使用 stdin 或请求文件，避免写入 Shell 历史。反馈问题时，请用示例数据替换真实凭据。
