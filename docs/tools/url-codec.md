# URL 编解码

URL 参数、完整 URL 和表单内容的编码与解码。

CLI：`url-codec`

## 使用方法

选择编码或解码，再选择参数组件、完整 URL 或表单参数模式。粘贴内容后执行；表单模式的加号和空格处理与其他模式不同。

## 示例

输入：

```text
hello 世界 + &
```

结果：

```text
hello%20%E4%B8%96%E7%95%8C%20%2B%20%26
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `operation` | 操作 | `encode` | `encode`、`decode` |
| `mode` | 模式 | `component` | `component`、`url`、`form` |

## CLI 调用

```sh
devkit describe url-codec
```

从文件读取：

```sh
devkit run url-codec --input-file ./input.txt
```

## 注意事项

表单模式把 `+` 作为空格处理；解码内容须为 UTF-8。
