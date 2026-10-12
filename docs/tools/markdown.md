# Markdown

本地预览和 HTML 导出；移除脚本与外部资源。

类别：文本与匹配 · CLI ID：`markdown` · 本机处理

## 怎么用

输入或导入 Markdown 后执行，查看清理后的 HTML 预览，也可切换文本结果。预览不会加载外部资源或运行脚本。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
# DevKit

- 原生工具箱
- **本地处理**

```js
const hello = "world";
```
```

## 参数参考

此工具无需额外算法参数，使用输入内容即可执行。

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe markdown
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run markdown --input-file ./input.txt
```

## 边界与注意事项

HTML 白名单清理；禁止外部资源；不支持活动嵌入。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
