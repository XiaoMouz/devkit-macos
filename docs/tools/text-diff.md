# 文本对比

逐行比较，保留两份输入，输出增删行。

类别：文本与匹配 · CLI ID：`text-diff` · 本机处理

## 怎么用

将原文和修改后的文本分别填入两份输入，选择是否忽略行首尾空白，执行后查看增删摘要与逐行明细。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
hello
world
```

第二份输入：

```text
hello
Web developer
```

默认配置下的结果：

```text
  hello
− world
+ Web developer
```

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `ignoreWhitespace` | 忽略行首尾空白 | `false` | `true` / `false` |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe text-diff
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run text-diff --input-file ./input.txt --secondary-file ./secondary.txt
```

## 边界与注意事项

逐行增删与忽略行首尾空白；共 10000 行；尚无字符级高亮和差异跳转。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
