# Mock 数据

根据字段模板生成 JSON 或 CSV 测试数据。

CLI：`mock-data`

## 使用方法

在输入中写字段名与字段类型的 JSON 对象，设置条数、种子和 JSON / CSV 格式后生成。同一种子与配置便于重复得到相同测试数据。

## 示例

输入：

```json
{"id":"index","name":"name","email":"email","active":"boolean","score":"integer"}
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `count` | 条数 | `10` | 1–10000 |
| `seed` | 可重复种子 | `42` | 0–2147483647 |
| `format` | 格式 | `json` | `json`、`csv` |

## CLI 调用

```sh
devkit describe mock-data
```

从文件读取：

```sh
devkit run mock-data --input-file ./input.txt
```

## 注意事项

相同种子与配置生成相同的测试数据。不要将测试数据用作安全凭据。
