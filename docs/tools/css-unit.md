# CSS 单位

在 px、rem、em、vw 和 vh 之间换算。

CLI：`css-unit`

## 使用方法

输入长度，选择来源和目标单位，按需设置根字号、父字号及视口宽高。执行后核对结果所依据的上下文参数。

## 示例

输入：

```text
24
```

结果：

```text
1.5rem
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `from` | 源单位 | `px` | `px`、`rem`、`em`、`vw`、`vh` |
| `to` | 目标单位 | `rem` | `px`、`rem`、`em`、`vw`、`vh` |
| `root` | 根字号 px | `16` | 1–256 |
| `parent` | 父字号 px | `16` | 1–256 |
| `width` | 视口宽度 px | `1440` | 1–20000 |
| `height` | 视口高度 px | `900` | 1–20000 |

## CLI 调用

```sh
devkit describe css-unit
```

从文件读取：

```sh
devkit run css-unit --input-file ./input.txt
```

## 注意事项

`rem` 使用根字号，`em` 使用父字号，`vw` / `vh` 使用视口宽高。
