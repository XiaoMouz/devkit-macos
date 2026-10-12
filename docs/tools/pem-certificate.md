# PEM 与证书

查看 X.509 证书的主题、有效期和 SHA-256 指纹。

CLI：`pem-certificate`

## 使用方法

粘贴 PEM 证书，或导入 PEM / DER 文件，执行后查看主题、有效期和 SHA-256。准备的输入应是证书内容，不是私钥。

## CLI 调用

```sh
devkit describe pem-certificate
```

从文件读取：

```sh
devkit run pem-certificate --file ./certificate.pem
```

## 注意事项

读取首张 PEM / DER 证书，不验证信任链或解析私钥。
