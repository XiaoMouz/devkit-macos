# MIME 类型

查询扩展名与 MIME 类型。

CLI：`mime-types`

## 使用方法

输入扩展名或类型标识，例如 json，执行后查看系统 UTType 数据库中的 MIME 类型信息。

## 示例

输入：

```text
json
```

结果：

```text
MIME: application/json
扩展名: json
UTType: public.json
说明: JSON
```

## CLI 调用

```sh
devkit describe mime-types
```

从文件读取：

```sh
devkit run mime-types --input-file ./input.txt
```

## 注意事项

可查询的类型取决于当前 macOS 的 UTType 数据库。
