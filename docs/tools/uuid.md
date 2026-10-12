# UUID

生成 UUID v4 或 v7，支持批量、大小写与连字符设置。

CLI：`uuid`

## 使用方法

选择 v4 或 v7，设置数量、大小写和连字符，点击生成。v4 为随机 UUID，v7 带时间排序信息。

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `version` | 版本 | `v4` | `v4`、`v7` |
| `count` | 数量 | `5` | 1–1000 |
| `uppercase` | 大写 | `false` | `true` / `false` |
| `hyphens` | 保留连字符 | `true` | `true` / `false` |

## CLI 调用

```sh
devkit describe uuid
```

生成一个结果：

```sh
devkit run uuid --text '' --option count=1
```

## 注意事项

UUID v7 在同一毫秒内不保证生成顺序。
