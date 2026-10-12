# 命名与大小写

camelCase、PascalCase、snake_case 与 kebab-case。

类别：文本与匹配 · CLI ID：`text-case` · 本机处理

## 怎么用

输入单词或变量名，选择 camelCase、PascalCase、snake_case 等目标形式后执行。标点会作为分词边界。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
helloWorld HTTPServer
```

默认配置下的结果：

```text
helloWorldHttpServer
```

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `mode` | 格式 | `camelCase` | `camelCase`、`PascalCase`、`snake_case`、`kebab-case`、`UPPERCASE`、`lowercase` |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe text-case
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run text-case --input-file ./input.txt
```

## 边界与注意事项

camel/Pascal/snake/kebab/大写/小写；标点作为分词边界。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
