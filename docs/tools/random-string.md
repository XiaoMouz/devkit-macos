# 随机字符串

使用系统安全随机源，自定义字符集与批量生成。

类别：标识与测试数据 · CLI ID：`random-string` · 本机处理

## 怎么用

设置字符集、长度、数量和是否排除相似字符，点击生成。结果每次不同，可以按条目复制，也可以复制全部。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 结果示例

生成结果每次不同。先把数量设为 1，确认格式符合需要，再增加数量。

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `length` | 长度 | `24` | 1–4096 |
| `count` | 数量 | `5` | 1–1000 |
| `alphabet` | 字符集 | `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789` | 文本 |
| `excludeSimilar` | 排除易混淆字符 | `true` | `true` / `false` |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe random-string
```

生成一个结果：

```sh
devkit run random-string --text '' --option count=1
```

## 边界与注意事项

安全随机、无偏采样、Unicode 字符集；总字符上限 100000。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
