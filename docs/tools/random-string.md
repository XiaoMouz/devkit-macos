# 随机字符串

按字符集、长度和数量生成随机字符串。

CLI：`random-string`

## 使用方法

设置字符集、长度、数量和是否排除相似字符，点击生成。

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `length` | 长度 | `24` | 1–4096 |
| `count` | 数量 | `5` | 1–1000 |
| `alphabet` | 字符集 | `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789` | 文本 |
| `excludeSimilar` | 排除易混淆字符 | `true` | `true` / `false` |

## CLI 调用

```sh
devkit describe random-string
```

生成一个结果：

```sh
devkit run random-string --text '' --option count=1
```

## 注意事项

一次生成的总字符数上限为 100,000。
