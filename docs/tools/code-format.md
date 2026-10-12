# 代码格式化

格式化 JavaScript、TypeScript、HTML、CSS 和 SQL。

CLI：`code-format`

## 使用方法

选择语言，粘贴代码并设置缩进；SQL 还需选择方言。点击顶部主按钮执行。

## 示例

输入：

```text
const user={name:"Ada",active:true};
```

结果：

```text
const user = { name: "Ada", active: true };

```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `language` | 语言 | `javascript` | `javascript`、`typescript`、`html`、`css`、`sql` |
| `indent` | 缩进 | `2` | 1–8 |
| `dialect` | SQL 方言 | `sql` | `sql`、`mysql`、`postgresql`、`sqlite`、`transactsql` |

## CLI 调用

```sh
devkit describe code-format
```

从文件读取：

```sh
devkit run code-format --input-file ./input.txt
```
