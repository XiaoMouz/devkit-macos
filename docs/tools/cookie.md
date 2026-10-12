# Cookie

解析 Cookie 和 Set-Cookie 字段。

CLI：`cookie`

## 使用方法

选择“Cookie 请求头”或“Set-Cookie 响应头”模式，粘贴请求 Cookie 或响应 Set-Cookie 文本后解析。多行 Set-Cookie 会保留属性，Expires 中的逗号不会当成条目分隔。

## 示例

输入：

```text
session=example; Path=/; HttpOnly; Secure; SameSite=Lax
```

结果：

```text
[
  {
    "name" : "session",
    "value" : "example"
  },
  {
    "name" : "Path",
    "value" : "/"
  },
  {
    "name" : "HttpOnly",
    "value" : "true"
  },
  {
    "name" : "Secure",
    "value" : "true"
  },
  {
    "name" : "SameSite",
    "value" : "Lax"
  }
]
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `mode` | 类型 | `set-cookie` | `set-cookie`、`cookie` |

## CLI 调用

```sh
devkit describe cookie
```

从文件读取：

```sh
devkit run cookie --input-file ./input.txt
```

## 注意事项

多条 Set-Cookie 使用换行分隔；Expires 属性中的逗号会保留。
