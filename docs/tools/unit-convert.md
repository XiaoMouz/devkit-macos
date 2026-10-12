# 单位转换

文件大小、时长和速率换算。

CLI：`unit-convert`

## 使用方法

输入数值，选择同类的来源与目标单位，再执行。KiB / MiB 使用 1024 进制，KB / MB 使用 1000 进制。

## 示例

输入：

```text
1024
```

结果：

```text
1048576 B
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `from` | 源单位 | `KiB` | `B`、`KB`、`MB`、`GB`、`KiB`、`MiB`、`GiB`、`ms`、`s`、`min`、`h`、`bit/s`、`Kbit/s`、`Mbit/s`、`MB/s` |
| `to` | 目标单位 | `B` | `B`、`KB`、`MB`、`GB`、`KiB`、`MiB`、`GiB`、`ms`、`s`、`min`、`h`、`bit/s`、`Kbit/s`、`Mbit/s`、`MB/s` |

## CLI 调用

```sh
devkit describe unit-convert
```

从文件读取：

```sh
devkit run unit-convert --input-file ./input.txt
```

## 注意事项

KB / MB 使用 1000 进制，KiB / MiB 使用 1024 进制。
