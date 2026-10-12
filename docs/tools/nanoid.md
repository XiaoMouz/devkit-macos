# Nano ID

按长度和字符集生成 Nano ID。

CLI：`nanoid`

## 使用方法

设置长度、数量与字符集，点击生成。

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `length` | 长度 | `21` | 1–4096 |
| `count` | 数量 | `5` | 1–1000 |
| `alphabet` | 字符集 | `_-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ` | 文本 |

## CLI 调用

```sh
devkit describe nanoid
```

生成一个结果：

```sh
devkit run nanoid --text '' --option count=1
```

## 注意事项

一次生成的总字符数上限为 100,000。
