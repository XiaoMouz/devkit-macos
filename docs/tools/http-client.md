# HTTP 调试

显式发送请求；响应、状态与耗时仅留在当前会话。

类别：Web 与网络 · CLI ID：`http-client` · 主动执行时联网

## 怎么用

填写完整 HTTP/HTTPS 地址，选择方法，以键值行填写请求头，并按需输入请求体。点击“发送请求”，再分别查看响应正文与状态/响应头。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
https://example.com
```

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `method` | 方法 | `GET` | `GET`、`POST`、`PUT`、`PATCH`、`DELETE`、`HEAD`、`OPTIONS` |
| `headers` | 请求头 JSON | `{}` | 文本 |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe http-client
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run http-client --input-file ./input.txt --secondary-file ./secondary.txt --allow-network
```

## 边界与注意事项

HTTP/HTTPS 方法、头、正文、状态；临时会话，响应上限 5 MiB。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
