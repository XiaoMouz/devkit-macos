# Base64

UTF-8 文本的 Base64 编码与解码，支持标准和 URL 安全模式 格式。

CLI：`base64`

## 使用方法

选择编码或解码，按来源决定是否启用 URL 安全模式；编码时可选择是否保留填充。输入文本后点击顶部主按钮。

![Base64 编码结果](/images/base64.png)

## 示例

输入：

```text
hello
```

结果：

```text
aGVsbG8=
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `operation` | 操作 | `encode` | `encode`、`decode` |
| `urlSafe` | URL 安全模式 | `false` | `true` / `false` |
| `padding` | 编码保留填充 | `true` | `true` / `false` |

## CLI 调用

```sh
devkit describe base64
```

从文件读取：

```sh
devkit run base64 --input-file ./input.txt
```

## 注意事项

解码结果须为 UTF-8 文本。图片编解码请使用 [Data URL](data-url.md)。
