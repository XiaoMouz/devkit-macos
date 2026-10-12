# 代码格式化

Prettier 格式化 JS / TS / HTML / CSS；SQL 可选方言。

类别：代码与图形 · CLI ID：`code-format` · 本机处理

## 怎么用

选择语言，粘贴代码并设置缩进；SQL 还需选择方言。执行后查看格式化结果，原程序不会运行。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
const user={name:"Ada",active:true};
```

默认配置下的结果：

```text
const user = { name: "Ada", active: true };

```

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `language` | 语言 | `javascript` | `javascript`、`typescript`、`html`、`css`、`sql` |
| `indent` | 缩进 | `2` | 1–8 |
| `dialect` | SQL 方言 | `sql` | `sql`、`mysql`、`postgresql`、`sqlite`、`transactsql` |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe code-format
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run code-format --input-file ./input.txt
```

## 边界与注意事项

Prettier JS/TS/HTML/CSS，SQL Formatter 多方言；不执行输入程序。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
