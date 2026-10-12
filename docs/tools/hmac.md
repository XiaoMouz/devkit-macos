# HMAC

使用密钥计算 SHA-256 或 SHA-512 消息认证码。

CLI：`hmac`

## 使用方法

输入消息，选择算法，填写密钥并确认密钥编码是 UTF-8、十六进制或 Base64。选择输出编码后执行。

## 示例

输入：

```text
hello
```

密钥填写 `example-key`，保持默认 UTF-8 与 SHA-256。

使用上述演示密钥与默认算法的结果：

```text
a866e07b5eafdf688740211b767b111eb9ce3c0da0b1ec77f1e9205ee440dbf6
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `algorithm` | 算法 | `SHA-256` | `SHA-256`、`SHA-512` |
| `key` | 密钥 | 空 | 文本 |
| `keyFormat` | 密钥格式 | `utf8` | `utf8`、`hex`、`base64` |
| `output` | 输出 | `hex` | `hex`、`base64` |

## CLI 调用

```sh
devkit describe hmac
```

带密钥的调用建议使用受控请求文件，避免写入 Shell 历史：

将下面的示例请求保存为 `request.json`：

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
