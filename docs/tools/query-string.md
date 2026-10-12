# 查询参数

解析、生成和排序查询参数，保留重复键与空值。

CLI：`query-string`

## 使用方法

解析模式输入查询字符串；生成模式输入有序键值 JSON；排序模式整理参数顺序。根据来源选择是否采用表单语义，重复键会保留。

## 示例

输入：

```text
tag=swift&tag=web&q=hello+world
```

结果：

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

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `operation` | 操作 | `parse` | `parse`、`build`、`sort` |
| `form` | 表单 + 代表空格 | `true` | `true` / `false` |

## CLI 调用

```sh
devkit describe query-string
```

从文件读取：

```sh
devkit run query-string --input-file ./input.txt
```

## 注意事项

表单模式将 `+` 解释为空格。使用有序键值对表示重复参数。
