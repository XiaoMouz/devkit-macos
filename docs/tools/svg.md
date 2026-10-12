# SVG 工作台

优化 SVG 源码并预览图形。

CLI：`svg`

## 使用方法

粘贴或导入 SVG 源码后执行，查看优化结果和受限预览。输入含脚本、实体或外链时会被拒绝。

## 示例

输入：

```text
<svg xmlns="http://www.w3.org/2000/svg" width="240" height="160"><rect width="240" height="160" rx="28" fill="#3478f6"/><circle cx="120" cy="80" r="42" fill="white"/></svg>
```

## CLI 调用

```sh
devkit describe svg
```

从文件读取：

```sh
devkit run svg --input-file ./input.txt
```

## 注意事项

含脚本、实体或外部引用的输入会被拒绝。当前仅导出 SVG，不提供栅格图片导出。
