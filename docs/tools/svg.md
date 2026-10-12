# SVG 工作台

清理脚本与外部引用，优化 SVG 并在受限视图预览。

类别：代码与图形 · CLI ID：`svg` · 本机处理

## 怎么用

粘贴或导入 SVG 源码后执行，查看优化结果和受限预览。输入含脚本、实体或外链时会被拒绝。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
<svg xmlns="http://www.w3.org/2000/svg" width="240" height="160"><rect width="240" height="160" rx="28" fill="#3478f6"/><circle cx="120" cy="80" r="42" fill="white"/></svg>
```

## 参数参考

此工具无需额外算法参数，使用输入内容即可执行。

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe svg
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run svg --input-file ./input.txt
```

## 边界与注意事项

拒绝脚本/实体/外链；SVGO 优化与受限预览；尚无 SVG 栅格导出。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
