# 时间戳

Unix 秒、毫秒与日期时间互转。

CLI：`timestamp`

## 使用方法

选择秒、毫秒或日期输入，选择时区后转换。需要普通日期时使用日期时间选择器；切换输入模式会保留毫秒精度。

## 示例

输入：

```text
1700000000
```

以 `Asia/Shanghai` 为时区，`1700000000` 秒对应 `2023-11-15 06:13:20`。改变时区会改变显示日期，不改变这一瞬间。

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `unit` | 时间戳单位 | `seconds` | `seconds`、`milliseconds` |
| `timezone` | 时区 | `系统当前时区` | 文本 |

## CLI 调用

```sh
devkit describe timestamp
```

从文件读取：

```sh
devkit run timestamp --input-file ./input.txt
```

## 注意事项

秒与毫秒按所选单位解释；结果使用所选时区显示。
