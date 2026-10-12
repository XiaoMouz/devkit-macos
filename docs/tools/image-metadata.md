# 图片信息

查看图片尺寸、EXIF 和色彩信息，或移除元数据。

CLI：`image-metadata`

## 使用方法

载入图片后查看元数据。需要清理时开启移除选项并重新执行，导出重新编码的图片。

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `strip` | 导出移除元数据的 PNG | `false` | `true` / `false` |

## CLI 调用

```sh
devkit describe image-metadata
```

从文件读取：

```sh
devkit run image-metadata --file ./image.png
```

## 注意事项

移除元数据会重新编码图片，输出 PNG。
