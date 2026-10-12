# 颜色转换

转换 HEX、RGB、HSL 颜色值与透明度。

CLI：`color`

## 使用方法

输入颜色值或使用颜色选择器，执行后查看 sRGB 的 HEX、RGB、HSL 和透明度表示，可逐项复制。

## 示例

输入：

```text
#3478f6
```

结果：

```text
#3478F6
rgb(52 120 246 / 1)
hsl(218.97 91.51% 58.43% / 1)
```

## CLI 调用

```sh
devkit describe color
```

从文件读取：

```sh
devkit run color --input-file ./input.txt
```
