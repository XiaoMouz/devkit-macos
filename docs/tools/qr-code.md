# 二维码

文本生成 QR，或选择图片识别；PNG 导出。

类别：标识与测试数据 · CLI ID：`qr-code` · 本机处理

## 怎么用

生成模式输入网址或文本，选择纠错等级和缩放，生成后预览、复制或保存 PNG。识别模式选择、拖入或粘贴二维码图片，再执行识别。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

![二维码生成与图片预览](/images/qr-code.png)

下面使用公开演示数据。输入内容：

```text
https://example.com
```

结果是可预览和保存的二维码 PNG，扫描内容为示例网址。

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `operation` | 操作 | `generate` | `generate`、`scan` |
| `correction` | 纠错级别 | `M` | `L`、`M`、`Q`、`H` |
| `scale` | 像素倍率 | `10` | 2–30 |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe qr-code
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run qr-code --input-file ./input.txt
```

## 边界与注意事项

Core Image 生成带静区 PNG；Vision 识别文本 QR；最多 2000 UTF-8 字节。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
