# URL 编解码

组件、完整 URL 和表单模式，明确处理空格与加号。

类别：编码与转换 · CLI ID：`url-codec` · 本机处理

## 怎么用

选择编码或解码，再选择参数组件、完整 URL 或表单参数模式。粘贴内容后执行；表单模式的加号和空格处理与其他模式不同。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
hello 世界 + &
```

默认配置下的结果：

```text
hello%20%E4%B8%96%E7%95%8C%20%2B%20%26
```

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `operation` | 操作 | `encode` | `encode`、`decode` |
| `mode` | 模式 | `component` | `component`、`url`、`form` |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe url-codec
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run url-codec --input-file ./input.txt
```

## 边界与注意事项

支持组件、完整 URL、WHATWG 表单字符集；解码要求 UTF-8。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
