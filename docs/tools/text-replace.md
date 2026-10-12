# 查找替换

使用普通文本或正则表达式查找替换。

CLI：`text-replace`

## 使用方法

填写原文、查找内容和替换内容。普通模式按字符串替换；正则模式填写 ECMAScript 表达式与标志。执行后在结果区确认替换范围。

## 示例

输入：

```text
hello world
hello DevKit
```

结果：

```text
Hello world
Hello DevKit
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `search` | 查找 | `hello` | 文本 |
| `replacement` | 替换 | `Hello` | 文本 |
| `regex` | 正则模式 | `false` | `true` / `false` |
| `flags` | 正则标志 | `g` | 文本 |

## CLI 调用

```sh
devkit describe text-replace
```

从文件读取：

```sh
devkit run text-replace --input-file ./input.txt
```
