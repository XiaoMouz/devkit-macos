# Markdown

预览 Markdown，导出 HTML。

CLI：`markdown`

## 使用方法

输入或导入 Markdown 后执行，查看清理后的 HTML 预览，也可切换文本结果。预览不会加载外部资源或运行脚本。

## 示例

输入：

```text
# DevKit

- 编码转换
- **文本处理**

```js
const hello = "world";
```
```

## CLI 调用

```sh
devkit describe markdown
```

从文件读取：

```sh
devkit run markdown --input-file ./input.txt
```

## 注意事项

预览会移除脚本和外部资源引用。
