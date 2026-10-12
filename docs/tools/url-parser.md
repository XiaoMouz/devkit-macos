# URL 解析

查看 URL 的协议、主机、端口、路径、查询和片段。

CLI：`url-parser`

## 使用方法

粘贴完整 URL 后解析，按条目查看协议、主机、端口、路径、查询和片段。需要编辑查询参数时转到“查询参数”工具。

## 示例

输入：

```text
https://example.com:8080/api/users?q=hello%20world#result
```

结果：

```text
协议: https
主机: example.com
端口: 8080
路径: /api/users
查询: q=hello%20world
片段: result
完整 URL: https://example.com:8080/api/users?q=hello%20world#result
```

## CLI 调用

```sh
devkit describe url-parser
```

从文件读取：

```sh
devkit run url-parser --input-file ./input.txt
```
