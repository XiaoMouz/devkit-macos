# Data URL

图片与 Data URL 互转。

类别：编码与转换 · CLI ID：`data-url` · 本机处理

## 怎么用

编码时选择、拖入或粘贴图片，点击“生成 Data URL”；解码时粘贴完整 data:image/... 内容，点击“还原图片”，再从结果区导出图片。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 准备样例

选择一份可以公开的PNG 或 JPEG 图片，先用较小尺寸验证结果，再处理自己的原图。

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `operation` | 操作 | `encode` | `encode`、`decode` |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe data-url
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run data-url --file ./image.png
```

## 边界与注意事项

图片编码为 Data URL；解码保留原始图片字节与格式，支持预览、复制和导出。自动识别 MIME 并校验图片；文本 Data URL 上限 5 MiB；不接受 SVG 或非图片载荷。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
