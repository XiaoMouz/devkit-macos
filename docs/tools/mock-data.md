# Mock 数据

字段模板生成 JSON / CSV；按种子生成可复现测试数据。

类别：标识与测试数据 · CLI ID：`mock-data` · 本机处理

## 怎么用

在输入中写字段名与字段类型的 JSON 对象，设置条数、种子和 JSON / CSV 格式后生成。同一种子与配置便于重复得到相同测试数据。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```json
{"id":"index","name":"name","email":"email","active":"boolean","score":"integer"}
```

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `count` | 条数 | `10` | 1–10000 |
| `seed` | 可重复种子 | `42` | 0–2147483647 |
| `format` | 格式 | `json` | `json`、`csv` |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe mock-data
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run mock-data --input-file ./input.txt
```

## 边界与注意事项

六类字段，JSON/CSV，可重复种子；不提供真实身份，不用于安全凭证。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
