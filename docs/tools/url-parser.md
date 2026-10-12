# URL 解析

分解协议、主机、端口、路径、查询与片段。

类别：Web 与网络 · CLI ID：`url-parser` · 本机处理

## 怎么用

粘贴完整 URL 后解析，按条目查看协议、主机、端口、路径、查询和片段。需要编辑查询参数时转到“查询参数”工具。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
https://example.com:8080/api/users?q=hello%20world#result
```

默认配置下的结果：

```text
协议: https
主机: example.com
端口: 8080
路径: /api/users
查询: q=hello%20world
片段: result
完整 URL: https://example.com:8080/api/users?q=hello%20world#result
```

## 参数参考

此工具无需额外算法参数，使用输入内容即可执行。

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe url-parser
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run url-parser --input-file ./input.txt
```

## 边界与注意事项

只读分解与完整 URL 显示；尚无逐字段重组表单。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
