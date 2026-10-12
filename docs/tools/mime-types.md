# MIME 类型

通过系统 Uniform Type 数据库查询扩展名或 MIME。

类别：Web 与网络 · CLI ID：`mime-types` · 本机处理

## 怎么用

输入扩展名或类型标识，例如 json，执行后查看系统 UTType 数据库中的 MIME 类型信息。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
json
```

默认配置下的结果：

```text
MIME: application/json
扩展名: json
UTType: public.json
说明: JSON
```

## 参数参考

此工具无需额外算法参数，使用输入内容即可执行。

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe mime-types
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run mime-types --input-file ./input.txt
```

## 边界与注意事项

系统 UTType 数据库；范围随系统版本变化。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
