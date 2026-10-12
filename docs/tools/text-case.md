# 命名与大小写

转换 camelCase、PascalCase、snake_case、kebab-case 和大小写。

CLI：`text-case`

## 使用方法

输入单词或变量名，选择 camelCase、PascalCase、snake_case 等目标形式后执行。标点会作为分词边界。

## 示例

输入：

```text
helloWorld HTTPServer
```

结果：

```text
helloWorldHttpServer
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `mode` | 格式 | `camelCase` | `camelCase`、`PascalCase`、`snake_case`、`kebab-case`、`UPPERCASE`、`lowercase` |

## CLI 调用

```sh
devkit describe text-case
```

从文件读取：

```sh
devkit run text-case --input-file ./input.txt
```
