# HTTP 调试

发送 HTTP 请求，查看响应正文、状态码、请求耗时与响应头。

CLI：`http-client`

## 使用方法

填写完整 HTTP/HTTPS 地址，选择方法，以键值行填写请求头，并按需输入请求体。点击“发送请求”，再分别查看响应正文与状态/响应头。

## 示例

输入：

```text
https://example.com
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `method` | 方法 | `GET` | `GET`、`POST`、`PUT`、`PATCH`、`DELETE`、`HEAD`、`OPTIONS` |
| `headers` | 请求头 JSON | `{}` | 文本 |

## CLI 调用

```sh
devkit describe http-client
```

从文件读取：

```sh
devkit run http-client --input-file ./input.txt --secondary-file ./secondary.txt --allow-network
```

## 注意事项

响应正文上限为 5 MiB。返回 4xx / 5xx 时，请结合状态码与响应正文排查。
