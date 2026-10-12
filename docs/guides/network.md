# 网络调试

HTTP、WebSocket 和 DNS 会在主动执行时联网；URL 解析、查询参数和 cURL 转换在本机处理。用你有权访问的测试服务进行调试，示例地址 `example.com` 用于演示。

## 发送 HTTP 请求

1. 打开「HTTP 调试」，输入完整 `http://` 或 `https://` URL。
2. 选择 GET、POST 等方法。
3. 用键值行添加请求头。需要 JSON 正文时设置 `Content-Type: application/json`。
4. 在请求体中填写正文，点击「发送请求」。
5. 查看响应正文，切到「状态与响应头」确认状态码和内容类型。

响应读取上限 5 MiB。可以根据响应类型保存 JSON、图片或其他文件。请求完成但返回 4xx/5xx 时，应根据服务端响应继续排查；这不同于连接超时或无法解析域名。

终端中的请求头参数是 JSON 对象，复杂请求建议保存为文件：

```json
{
  "id": "http-client",
  "input": {"text": "https://example.com", "secondary": ""},
  "options": {"method": "GET", "headers": "{\"Accept\":\"text/html\"}"}
}
```

```sh
devkit run --request request.json --allow-network --format json
```

## WebSocket 收发

填入 `ws://` 或 `wss://` 地址后点击连接，在左侧编辑消息并手动发送。右侧按消息展示发送和接收内容，点击消息复制完整值。完成后断开连接，关闭所属会话也会关闭连接。

会话上限为 1000 条 / 5 MiB，单条消息上限 1 MiB。历史不跨启动保存。CLI 是一次性连接、发送、接收后关闭，不加入应用窗口的持续连接。

## DNS 查询

输入域名，选择 A、AAAA、MX 等记录类型。解析器留空使用系统默认设置，也可指定解析器 IP 和端口。执行后查看服务器、答案和耗时。单次查询超时为 3 秒，不会自动轮询。

```sh
devkit run dns --text example.com --option record=A --allow-network
```

## 从 cURL 开始

把命令粘贴到「cURL 转换」，选择 fetch 或 JSON 输出。工具静态解析常见 URL、方法、请求头和正文，不执行命令；Shell 运算与 `@文件` 输入会被拒绝。生成后确认凭据和目标地址，再在自己的环境运行。

## 相关工具

[HTTP 调试](../tools/http-client.md) · [WebSocket](../tools/websocket.md) · [DNS](../tools/dns.md) · [URL 解析](../tools/url-parser.md) · [查询参数](../tools/query-string.md) · [Cookie](../tools/cookie.md) · [HTTP 状态码](../tools/http-status.md)
