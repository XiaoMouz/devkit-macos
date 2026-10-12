# HMAC

SHA-256 / SHA-512 消息认证码；密钥仅在当前会话中使用。

类别：摘要与令牌 · CLI ID：`hmac` · 本机处理

## 怎么用

输入消息，选择算法，填写密钥并确认密钥编码是 UTF-8、Hex 或 Base64。选择输出编码后执行。下方示例使用公开演示密钥 example-key。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
hello
```

密钥填写 `example-key`，保持默认 UTF-8 与 SHA-256。

使用上述演示密钥与默认算法的结果：

```text
a866e07b5eafdf688740211b767b111eb9ce3c0da0b1ec77f1e9205ee440dbf6
```

## 参数参考

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `algorithm` | 算法 | `SHA-256` | `SHA-256`、`SHA-512` |
| `key` | 密钥 | 空 | 文本 |
| `keyFormat` | 密钥格式 | `utf8` | `utf8`、`hex`、`base64` |
| `output` | 输出 | `hex` | `hex`、`base64` |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe hmac
```

带密钥的调用建议使用受控请求文件，避免写入 Shell 历史：

将下面的公开演示请求保存为 `request.json`：

```json
{
  "id": "hmac",
  "input": {"text": "hello"},
  "options": {"key": "example-key", "keyFormat": "utf8", "algorithm": "SHA-256", "output": "hex"}
}
```

```sh
devkit run --request request.json --format json
```

## 边界与注意事项

SHA-256/SHA-512；UTF-8/Hex/Base64 密钥；Hex/Base64 输出。

这里的空密钥默认值用于等待输入，请填写自己的密钥；文档中的 example-key 仅是公开测试值。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
