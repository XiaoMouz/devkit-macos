# 查找替换

普通文本或 ECMAScript 正则，保留原文并预览结果。

类别：文本与匹配 · CLI ID：`text-replace` · 本机处理

## 怎么用

填写原文、查找内容和替换内容。普通模式按字符串替换；正则模式填写 ECMAScript 表达式与标志。执行后在结果区确认替换范围。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
hello world
hello DevKit
```

默认配置下的结果：

```text
Hello world
Hello DevKit
```

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `search` | 查找 | `hello` | 文本 |
| `replacement` | 替换 | `Hello` | 文本 |
| `regex` | 正则模式 | `false` | `true` / `false` |
| `flags` | 正则标志 | `g` | 文本 |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe text-replace
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run text-replace --input-file ./input.txt
```

## 边界与注意事项

普通或 ECMAScript 正则；结果与原文分离。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
