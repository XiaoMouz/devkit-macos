# 文本统计

统计字符、Unicode 码点、UTF-16、UTF-8 字节与行数。

CLI：`text-stats`

## 使用方法

输入或导入文本后执行，比较字素、码点、UTF-16、UTF-8 字节与行数。Emoji 的屏幕字符数与内部编码长度可能不同。

## 示例

输入：

```text
Hello 世界 👩‍💻
```

结果：

```text
字素: 10
Unicode 码点: 12
UTF-16 单元: 14
UTF-8 字节: 24
行: 1
词（空白分隔）: 3
```

## CLI 调用

```sh
devkit describe text-stats
```

从文件读取：

```sh
devkit run text-stats --input-file ./input.txt
```

## 注意事项

词数按空白分隔。组合 Emoji 的字素数与码点数可能不同。
