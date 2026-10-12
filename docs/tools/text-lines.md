# 文本行处理

排序、去重、去空行、编号和添加前后缀。

CLI：`text-lines`

## 使用方法

输入多行文本，选择排序、去重、去空行、编号或前后缀处理；需要前后缀时填写对应内容，再执行。结果与原输入分离。

## 示例

输入：

```text
banana
apple
banana

cherry
```

结果：

```text
banana
apple

cherry
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `mode` | 操作 | `deduplicate` | `deduplicate`、`sort`、`reverse-sort`、`remove-empty`、`number`、`affix` |
| `prefix` | 前缀 | 空 | 文本 |
| `suffix` | 后缀 | 空 | 文本 |

## CLI 调用

```sh
devkit describe text-lines
```

从文件读取：

```sh
devkit run text-lines --input-file ./input.txt
```
