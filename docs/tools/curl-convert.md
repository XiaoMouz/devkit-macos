# cURL 转换

将 cURL 命令转换为 fetch 代码或 JSON。

CLI：`curl-convert`

## 使用方法

粘贴 cURL 命令，选择 fetch 或 JSON 输出后转换。工具只解析命令，不执行请求；生成代码后需自己确认目标和凭据。

## 示例

输入：

```text
curl 'https://example.com/api' -X POST -H 'Content-Type: application/json' -d '{"hello":"world"}'
```

结果：

```text
const response = await fetch("https://example.com/api", {
  "method": "POST",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "{\"hello\":\"world\"}"
});
const data = await response.text();
```

## 参数参考

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `format` | 输出 | `fetch` | `fetch`、`json` |

## CLI 调用

```sh
devkit describe curl-convert
```

从文件读取：

```sh
devkit run curl-convert --input-file ./input.txt
```

## 注意事项

不支持 Shell 运算和 `@文件` 输入。
