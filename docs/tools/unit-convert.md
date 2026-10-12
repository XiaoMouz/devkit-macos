# 单位转换

文件大小、时长和速率，明确 SI 与 IEC。

类别：时间与数值 · CLI ID：`unit-convert` · 本机处理

## 怎么用

输入数值，选择同类的来源与目标单位，再执行。KiB / MiB 使用 1024 进制，KB / MB 使用 1000 进制。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
1024
```

默认配置下的结果：

```text
1048576 B
```

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `from` | 源单位 | `KiB` | `B`、`KB`、`MB`、`GB`、`KiB`、`MiB`、`GiB`、`ms`、`s`、`min`、`h`、`bit/s`、`Kbit/s`、`Mbit/s`、`MB/s` |
| `to` | 目标单位 | `B` | `B`、`KB`、`MB`、`GB`、`KiB`、`MiB`、`GiB`、`ms`、`s`、`min`、`h`、`bit/s`、`Kbit/s`、`Mbit/s`、`MB/s` |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe unit-convert
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run unit-convert --input-file ./input.txt
```

## 边界与注意事项

文件大小、时长、速率；SI/IEC 区分。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
