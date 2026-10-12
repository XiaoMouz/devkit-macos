# 图片尺寸

等比缩放、填充画布或居中裁剪图片。

CLI：`image-resize`

## 使用方法

载入图片并填写目标宽高，选择等比缩放、透明画布或居中裁剪后执行。预览确认边界与裁切，导出 PNG。

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `width` | 宽 px | `800` | 1–10000 |
| `height` | 高 px | `600` | 1–10000 |
| `mode` | 方式 | `scale` | `scale`、`fit`、`fill` |

## CLI 调用

```sh
devkit describe image-resize
```

从文件读取：

```sh
devkit run image-resize --file ./image.png
```
