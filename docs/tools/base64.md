# Base64

UTF-8 文本编解码；标准 / URL Safe，支持文本导出。

类别：编码与转换 · CLI ID：`base64` · 本机处理

## 怎么用

选择编码或解码，按来源决定是否启用 URL Safe；编码时可选择是否保留填充。输入文本后点击顶部主按钮。解码示例是 aGVsbG8=，编码示例是 hello。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

![Base64 编码结果](/images/base64.png)

## 试一个例子

下面使用公开演示数据。输入内容：

```text
hello
```

默认配置下的结果：

```text
aGVsbG8=
```

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `operation` | 操作 | `encode` | `encode`、`decode` |
| `urlSafe` | URL Safe | `false` | `true` / `false` |
| `padding` | 编码保留填充 | `true` | `true` / `false` |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe base64
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run base64 --input-file ./input.txt
```

## 边界与注意事项

标准 / URL Safe 的 UTF-8 文本；非 UTF-8 明确拒绝；Spotlight 系统链路待实测。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
