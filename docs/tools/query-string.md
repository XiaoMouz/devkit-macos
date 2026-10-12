# 查询参数

保留重复键和空值，JSON 键值对与查询字符串互转。

类别：Web 与网络 · CLI ID：`query-string` · 本机处理

## 怎么用

解析模式输入查询字符串；生成模式输入有序键值 JSON；排序模式整理参数顺序。根据来源选择是否采用表单语义，重复键会保留。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
tag=swift&tag=web&q=hello+world
```

默认配置下的结果：

```text
[
  {
    "name" : "tag",
    "value" : "swift"
  },
  {
    "name" : "tag",
    "value" : "web"
  },
  {
    "name" : "q",
    "value" : "hello world"
  }
]
```

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `operation` | 操作 | `parse` | `parse`、`build`、`sort` |
| `form` | 表单 + 代表空格 | `true` | `true` / `false` |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe query-string
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run query-string --input-file ./input.txt
```

## 边界与注意事项

有序键值 JSON、重复键、空值、排序、生成；不提供电子表格式编辑。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
