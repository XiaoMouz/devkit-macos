# 哈希摘要

计算 MD5、SHA-1、SHA-256 和 SHA-512 摘要。

CLI：`hash`

## 使用方法

输入要计算摘要的文本，选择算法与十六进制大小写，点击“计算摘要”。换行和前后空格都会参与计算。

## 示例

输入：

```text
hello
```

结果：

```text
2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `algorithm` | 算法 | `SHA-256` | `MD5`、`SHA-1`、`SHA-256`、`SHA-512` |
| `uppercase` | 大写 | `false` | `true` / `false` |

## CLI 调用

```sh
devkit describe hash
```

从文件读取：

```sh
devkit run hash --input-file ./input.txt
```

## 注意事项

MD5 和 SHA-1 用于兼容旧系统及校验场景。
