# JWT 工作台

解析 JWT 头部与载荷，并支持 HS256 验签。

CLI：`jwt`

## 使用方法

粘贴三段式 JWT，先解码头部和载荷。需要 HS256 验签时启用验签并输入密钥；分别检查签名结论和 exp / nbf 时间状态。示例令牌仅用于解码演示。

## 示例

输入：

```text
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFkYSJ9.AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
```

该样例的签名是演示占位内容。默认用于查看头部与载荷，不代表验签通过。

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `verify` | 验证 HS256 签名 | `false` | `true` / `false` |
| `key` | HS256 密钥 | 空 | 文本 |

## CLI 调用

```sh
devkit describe jwt
```

从文件读取：

```sh
devkit run jwt --input-file ./input.txt
```

## 注意事项

分别查看 HS256 签名和 `exp` / `nbf` 时间状态。`aud`、`iss` 等业务声明需要按你的应用规则检查。
