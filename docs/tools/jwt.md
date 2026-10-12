# JWT 工作台

解析 Header / Payload；可选 HS256 验签，解析不代表可信。

类别：摘要与令牌 · CLI ID：`jwt` · 本机处理

## 怎么用

粘贴三段式 JWT，先解码 Header 和 Payload。需要 HS256 验签时启用验签并输入密钥；分别检查签名结论和 exp / nbf 时间状态。示例令牌仅用于解码演示。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFkYSJ9.AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
```

该样例的签名是演示占位内容。默认用于查看 Header/Payload，不代表验签通过。

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `verify` | 验证 HS256 签名 | `false` | `true` / `false` |
| `key` | HS256 密钥 | 空 | 文本 |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe jwt
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run jwt --input-file ./input.txt
```

## 边界与注意事项

Header/Payload 对象解析；HS256 验签与 exp/nbf 时间状态分别展示；不判断 aud/iss 业务可信度。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
