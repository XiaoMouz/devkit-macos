# 二维码

生成二维码 PNG，或从图片中识别二维码。

CLI：`qr-code`

## 使用方法

生成模式输入网址或文本，选择纠错等级和缩放，生成后预览、复制或保存 PNG。识别模式选择、拖入或粘贴二维码图片，再执行识别。

## 示例

![二维码生成与图片预览](/images/qr-code.png)

输入：

```text
https://example.com
```

结果是可预览和保存的二维码 PNG，扫描内容为示例网址。

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `operation` | 操作 | `generate` | `generate`、`scan` |
| `correction` | 纠错级别 | `M` | `L`、`M`、`Q`、`H` |
| `scale` | 像素倍率 | `10` | 2–30 |

## CLI 调用

```sh
devkit describe qr-code
```

从文件读取：

```sh
devkit run qr-code --input-file ./input.txt
```

## 注意事项

输入上限为 2000 个 UTF-8 字节。导出和排版时保留二维码四周的静区。
