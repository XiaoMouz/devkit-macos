# 颜色对比度

计算前景色与背景色的对比度，查看 WCAG AA / AAA 结果。

CLI：`contrast`

## 使用方法

分别选择前景色和背景色，执行后读取对比度以及不同字号下的 AA / AAA 结论。当前只接受不透明颜色。

## 示例

输入：

```text
#FFFFFF
```

结果：

```text
对比值: 4.0671:1
AA 普通文字 ≥4.5: 未通过
AA 大号文字 ≥3: 通过
AAA 普通文字 ≥7: 未通过
AAA 大号文字 ≥4.5: 未通过
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `background` | 背景颜色 | `#3478F6` | 文本 |

## CLI 调用

```sh
devkit describe contrast
```

从文件读取：

```sh
devkit run contrast --input-file ./input.txt
```

## 注意事项

仅支持不透明颜色。普通文字与大号文字的对比度要求不同。
