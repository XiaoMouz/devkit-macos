# 图片压缩

调整 JPEG 质量，或按目标体积压缩图片。

CLI：`image-compress`

## 使用方法

载入图片，设置 JPEG 质量和可选目标体积后压缩。查看实际大小；无法达到目标体积时根据提示调整尺寸或质量。

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `quality` | 质量上限 % | `85` | 10–100 |
| `targetKB` | 目标 KB（0 为不限） | `0` | 0–32000 |

## CLI 调用

```sh
devkit describe image-compress
```

从文件读取：

```sh
devkit run image-compress --file ./image.png
```

## 注意事项

输出为 JPEG。达不到目标体积时，可以降低质量或先调整图片尺寸。
