# 正则测试

ECMAScript 正则、捕获组和替换预览；独立进程可取消。

类别：文本与匹配 · CLI ID：`regex` · 本机处理

## 怎么用

输入待匹配文本，填写 ECMAScript 正则表达式和标志。匹配模式查看匹配与捕获；替换模式再填写替换模板，例如 $1。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
user@example.com
hello@devkit.app
```

默认配置下的结果：

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

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `pattern` | 表达式 | `([\w.-]+)@([\w.-]+)` | 文本 |
| `flags` | 标志 | `g` | 文本 |
| `operation` | 操作 | `match` | `match`、`replace` |
| `replacement` | 替换文本 | `$1@new.test` | 文本 |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe regex
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run regex --input-file ./input.txt
```

## 边界与注意事项

ECMAScript 标志、捕获和替换；隔离执行，最多 10000 个匹配。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
