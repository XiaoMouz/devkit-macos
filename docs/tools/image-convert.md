# 图片格式转换

在 PNG、JPEG 和 HEIC 格式之间转换。

CLI：`image-convert`

## 使用方法

载入图片，选择 PNG、JPEG 或 HEIC，按需设置质量，然后转换并导出。JPEG 会把透明背景合成为白色。

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `format` | 格式 | `png` | `png`、`jpeg`、`heic` |
| `quality` | 有损质量 % | `85` | 1–100 |

## CLI 调用

```sh
devkit describe image-convert
```

从文件读取：

```sh
devkit run image-convert --file ./image.png
```

## 注意事项

处理首帧图片。JPEG 的透明区域会合成为白色；需要透明度时选择 PNG。当前不支持 WebP 编码。
