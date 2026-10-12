# Data URL

图片与 Data URL 互转。

CLI：`data-url`

## 使用方法

编码时选择、拖入或粘贴图片，点击“生成 Data URL”；解码时粘贴完整 data:image/... 内容，点击“还原图片”，再从结果区导出图片。

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `operation` | 操作 | `encode` | `encode`、`decode` |

## CLI 调用

```sh
devkit describe data-url
```

从文件读取：

```sh
devkit run data-url --file ./image.png
```

## 注意事项

Data URL 文本上限 5 MiB；支持图片载荷，不支持 SVG。解码保留原图片格式。
