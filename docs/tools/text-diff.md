# 文本对比

逐行比较两份文本，查看增加与删除的内容。

CLI：`text-diff`

## 使用方法

将原文和修改后的文本分别填入两份输入，选择是否忽略行首尾空白，执行后查看增删摘要与逐行明细。

## 示例

输入：

```text
hello
world
```

第二份输入：

```text
hello
Web developer
```

结果：

```text
  hello
− world
+ Web developer
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `ignoreWhitespace` | 忽略行首尾空白 | `false` | `true` / `false` |

## CLI 调用

```sh
devkit describe text-diff
```

从文件读取：

```sh
devkit run text-diff --input-file ./input.txt --secondary-file ./secondary.txt
```

## 注意事项

两份输入合计上限为 10,000 行。结果按行比较。
