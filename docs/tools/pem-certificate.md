# PEM 与证书

本地 X.509 证书主题、有效期与 SHA-256 指纹。

类别：摘要与令牌 · CLI ID：`pem-certificate` · 本机处理

## 怎么用

粘贴 PEM 证书，或导入 PEM / DER 文件，执行后查看主题、有效期和 SHA-256。准备的输入应是证书内容，不是私钥。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 准备样例

选择一份可以公开的PEM / DER 证书文件。

## 参数参考

此工具无需额外算法参数，使用输入内容即可执行。

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe pem-certificate
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run pem-certificate --file ./certificate.pem
```

## 边界与注意事项

首张 PEM/DER X.509 的主题、有效期、SHA-256；不验信任链，不解析私钥。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
