# 代码压缩

压缩 JavaScript、CSS 和 HTML。

CLI：`code-minify`

## 使用方法

选择 JavaScript、CSS 或 HTML，输入代码后执行。JavaScript 使用保守方式移除空白与注释，不重命名标识符。

## 示例

输入：

```text
const user={name:"Ada",active:true};
```

结果：

```text
const user={name:"Ada",active:true};
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `language` | 语言 | `javascript` | `javascript`、`css`、`html` |

## CLI 调用

```sh
devkit describe code-minify
```

从文件读取：

```sh
devkit run code-minify --input-file ./input.txt
```

## 注意事项

JavaScript 压缩不重命名标识符。
