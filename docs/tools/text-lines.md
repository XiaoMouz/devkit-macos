# 文本行处理

排序、去重、去空行、编号和添加前后缀。

类别：文本与匹配 · CLI ID：`text-lines` · 本机处理

## 怎么用

输入多行文本，选择排序、去重、去空行、编号或前后缀处理；需要前后缀时填写对应内容，再执行。结果与原输入分离。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
banana
apple
banana

cherry
```

默认配置下的结果：

```text
banana
apple

cherry
```

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `mode` | 操作 | `deduplicate` | `deduplicate`、`sort`、`reverse-sort`、`remove-empty`、`number`、`affix` |
| `prefix` | 前缀 | 空 | 文本 |
| `suffix` | 后缀 | 空 | 文本 |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe text-lines
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run text-lines --input-file ./input.txt
```

## 边界与注意事项

排序、去重、去空行、编号、前后缀；保留原输入。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
