# JSON 工作台

格式化、压缩、JSONPath / Pointer、结构对比、Schema 校验与 TypeScript 类型。

类别：结构化数据 · CLI ID：`json` · 本机处理

## 怎么用

通过顶部功能菜单选择操作。路径查询需要填写语法和路径；结构对比与 Schema 校验需要第二份输入；类型生成可以指定根类型名称。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

![JSON 工作台](/images/json-workspace.png)

八种操作的完整步骤见 [JSON 任务指南](../guides/json.md)。

## 试一个例子

下面使用公开演示数据。输入内容：

```json
{"name":"DevKit","version":1,"users":[{"id":1,"name":"Ada"}]}
```

默认配置下的结果：

```text
{
  "name": "DevKit",
  "version": 1,
  "users": [
    {
      "id": 1,
      "name": "Ada"
    }
  ]
}
```

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `operation` | 功能 | `format` | `format`、`minify`、`validate`、`tree`、`query`、`diff`、`schema`、`typescript` |
| `syntax` | 查询语法 | `jsonpath` | `jsonpath`、`pointer` |
| `path` | 查询路径 | `$` | 文本 |
| `name` | TypeScript 类型名称 | `Root` | 文本 |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe json
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run json --input-file ./input.txt
```

## 边界与注意事项

统一入口：格式化、压缩、校验、路径列表、JSONPath/Pointer、结构对比、Draft 2020-12 Schema 校验与 TypeScript 类型推断。模式切换保留源 JSON，并分别保留对比文档与 Schema。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
