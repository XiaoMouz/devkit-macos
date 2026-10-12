# DNS 查询

查询 A、AAAA、CNAME、MX、TXT 等 DNS 记录。

CLI：`dns`

## 使用方法

输入域名、选择记录类型。解析器留空使用系统设置，或指定解析器 IP 与端口；执行后查看服务器、答案和耗时。

## 示例

输入：

```text
example.com
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `record` | 记录类型 | `A` | `A`、`AAAA`、`CNAME`、`MX`、`TXT`、`NS`、`SOA`、`CAA` |
| `resolver` | 解析器 IP（空为系统） | 空 | 文本 |
| `port` | 解析器端口 | `53` | 1–65535 |

## CLI 调用

```sh
devkit describe dns
```

从文件读取：

```sh
devkit run dns --input-file ./input.txt --allow-network
```

## 注意事项

单次查询超时为 3 秒。自定义解析器填写 IP 地址。
