# JSON 工作台

格式化、压缩、路径查询、结构对比、Schema 校验与 TypeScript 类型生成。

CLI：`json`

## 使用方法

通过顶部功能菜单选择操作。路径查询需要填写语法和路径；结构对比与 Schema 校验需要第二份输入；类型生成可以指定根类型名称。

![JSON 工作台](/images/json-workspace.png)

八种操作的完整步骤见 [JSON 任务指南](../guides/json.md)。

## 示例

输入：

```json
{"name":"DevKit","version":1,"users":[{"id":1,"name":"Ada"}]}
```

结果：

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

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `operation` | 功能 | `format` | `format`、`minify`、`validate`、`tree`、`query`、`diff`、`schema`、`typescript` |
| `syntax` | 查询语法 | `jsonpath` | `jsonpath`、`pointer` |
| `path` | 查询路径 | `$` | 文本 |
| `name` | TypeScript 类型名称 | `Root` | 文本 |

## CLI 调用

```sh
devkit describe json
```

从文件读取：

```sh
devkit run json --input-file ./input.txt
```

## 注意事项

Schema 使用 Draft 2020-12。折叠预览最多显示 10,000 个节点；复制和导出保留完整结果。
