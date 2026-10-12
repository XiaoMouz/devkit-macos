# cURL 转换

静态解析常用 cURL 参数，输出 fetch；不执行 Shell。

类别：Web 与网络 · CLI ID：`curl-convert` · 本机处理

## 怎么用

粘贴 cURL 命令，选择 fetch 或 JSON 输出后转换。工具只解析命令，不执行请求；生成代码后需自己确认目标和凭据。

运行完成后，从结果面板复制或导出。修改输入或参数后需要重新执行。

## 试一个例子

下面使用公开演示数据。输入内容：

```text
curl 'https://example.com/api' -X POST -H 'Content-Type: application/json' -d '{"hello":"world"}'
```

默认配置下的结果：

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

下表列出参数 ID，便于 CLI / AI 调用；界面只显示当前操作需要的参数。时区和当前时刻等默认值会随系统变化。

| 参数 | 名称 | 默认值 | 可选值或范围 |
| --- | --- | --- | --- |
| `format` | 输出 | `fetch` | `fetch`、`json` |

## CLI 调用

先在「设置 → CLI 与 AI」安装命令。查看参数：

```sh
devkit describe curl-convert
```

将示例输入保存为相应文件后执行；示例文件名需换成你的实际文件：

```sh
devkit run curl-convert --input-file ./input.txt
```

## 边界与注意事项

静态解析常见参数为 fetch/JSON；拒绝 Shell 运算和 @文件。

常规文本输入合计上限 5 MiB；普通文件输入上限 32 MiB，具体工具可能更低。详情见[文件与导出](../files.md)。

[返回工具目录](index.md) · [CLI 与 AI](../cli-and-ai.md) · [常见问题](../faq.md)
