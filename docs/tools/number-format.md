# 数字格式

设置小数位、舍入方式和千分位。

CLI：`number-format`

## 使用方法

输入十进制数字，设置小数位、舍入方式和分组符后执行。需要精确小数时，先核对输入和舍入规则。

## 示例

输入：

```text
1234567.895
```

结果：

```text
1,234,567.90
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `scale` | 小数位 | `2` | 0–20 |
| `rounding` | 舍入方式 | `plain` | `plain`、`bankers`、`down`、`up` |
| `grouping` | 千分位 | `true` | `true` / `false` |

## CLI 调用

```sh
devkit describe number-format
```

从文件读取：

```sh
devkit run number-format --input-file ./input.txt
```

## 注意事项

最多 38 位有效数字，不输出科学计数法。
