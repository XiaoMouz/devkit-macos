# HTTP 状态码

查询 HTTP 状态码的名称和含义。

CLI：`http-status`

## 使用方法

输入状态码，例如 404，执行后查看名称和说明。未收录的状态会提供 IANA 参考入口。

## 示例

输入：

```text
404
```

结果：

```text
404 · Not Found
未找到资源
```

## CLI 调用

```sh
devkit describe http-status
```

从文件读取：

```sh
devkit run http-status --input-file ./input.txt
```
