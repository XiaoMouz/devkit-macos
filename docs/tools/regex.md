# 正则测试

测试 ECMAScript 正则表达式，查看捕获组和替换结果。

CLI：`regex`

## 使用方法

输入待匹配文本，填写 ECMAScript 正则表达式和标志。匹配模式查看匹配与捕获；替换模式再填写替换模板，例如 $1。

## 示例

输入：

```text
user@example.com
hello@devkit.app
```

结果：

```text
[
  {
    "index": 0,
    "match": "user@example.com",
    "groups": [
      "user",
      "example.com"
    ]
  },
  {
    "index": 17,
    "match": "hello@devkit.app",
    "groups": [
      "hello",
      "devkit.app"
    ]
  }
]
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `pattern` | 表达式 | `([\w.-]+)@([\w.-]+)` | 文本 |
| `flags` | 标志 | `g` | 文本 |
| `operation` | 操作 | `match` | `match`、`replace` |
| `replacement` | 替换文本 | `$1@new.test` | 文本 |

## CLI 调用

```sh
devkit describe regex
```

从文件读取：

```sh
devkit run regex --input-file ./input.txt
```

## 注意事项

最多返回 10,000 个匹配。耗时过长的表达式会被终止。
