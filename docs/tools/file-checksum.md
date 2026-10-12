# 文件校验

计算文件摘要，并与预期值比较。

CLI：`file-checksum`

## 使用方法

选择文件并设置摘要算法，点击计算。需要核对下载文件时，把发布者提供的摘要填入预期值；结果会同时展示摘要与比较状态。大文件运行中可取消。

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `algorithm` | 算法 | `SHA-256` | `MD5`、`SHA-1`、`SHA-256`、`SHA-512` |
| `expected` | 期望摘要（可选） | 空 | 文本 |

## CLI 调用

```sh
devkit describe file-checksum
```

从文件读取：

```sh
devkit run file-checksum --file ./download.zip
```

## 注意事项

应用可通过流式读取校验大文件，运行中支持取消。CLI 文件输入上限为 32 MiB。
