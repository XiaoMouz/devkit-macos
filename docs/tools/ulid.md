# ULID

生成 ULID，或解析其中的时间。

CLI：`ulid`

## 使用方法

生成模式只需设置数量。解析模式填写已有 ULID，可查看其中的时间。

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `operation` | 操作 | `generate` | `generate`、`parse` |
| `count` | 数量 | `5` | 1–1000 |

## CLI 调用

```sh
devkit describe ulid
```

生成一个结果：

```sh
devkit run ulid --text '' --option count=1
```

## 注意事项

同一毫秒内生成的随机部分相互独立，不保证排序顺序。
