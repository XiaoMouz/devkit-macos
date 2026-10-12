# 命名与大小写

转换为小驼峰、大驼峰、下划线、短横线命名，或统一大写、小写。

CLI：`text-case`

## 使用方法

输入单词或变量名，选择小驼峰、大驼峰、下划线等目标形式后执行。标点会作为分词边界。

## 示例

输入：

```text
helloWorld HTTPServer
```

结果：

```text
helloWorldHttpServer
```

## 格式与 Spotlight 命令

应用内和 Spotlight 使用相同的格式名称，命令示例随界面语言更新。中文可输入 `text-case 小驼峰 hello world` 或 `case 大写 hello world`。

| 中文名称 | 英文名称 | 兼容的命令 / CLI 参数值 |
| --- | --- | --- |
| 小驼峰 | Camel Case | `camelCase` |
| 大驼峰 | Pascal Case | `PascalCase` |
| 下划线 | Snake Case | `snake_case` |
| 短横线 | Kebab Case | `kebab-case` |
| 大写 | Uppercase | `UPPERCASE` |
| 小写 | Lowercase | `lowercase` |

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
