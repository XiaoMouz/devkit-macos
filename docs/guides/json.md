# JSON 八种操作

JSON 的八种操作都在「JSON 工作台」。通过顶部功能菜单切换，源 JSON 会保留；结构对比和 Schema 有各自的第二输入。

![JSON 工作台的格式化和折叠预览](/images/json-workspace.png)

## 格式化与压缩

输入 `{"name":"DevKit","users":[{"id":1,"name":"Ada"}]}`，选择「格式化」并执行。结果默认以折叠视图显示，三角用于展开/收起对象和数组，数组旁显示元素数量。复制或导出的 JSON 不含这些预览标签。

选择「压缩」可去除格式空白，得到更紧凑的 JSON。格式化或压缩失败时，先检查引号、逗号和括号。

## 语法校验与路径列表

「语法校验」显示通过或失败的状态及错误明细。「路径列表」帮助查找嵌套字段。大 JSON 折叠预览最多显示 10,000 个节点，长值可能截断；完整结果仍可复制和导出。

## 路径查询

1. 选择「路径查询」。
2. 选择 JSONPath 或 JSON Pointer。
3. 输入路径，再执行。

对上面的示例：

| 语法 | 路径 | 查找内容 |
| --- | --- | --- |
| JSONPath | `$.users[0].name` | 第一个用户的名称 Ada |
| JSON Pointer | `/users/0/name` | 同一个名称 |
| JSON Pointer | 空路径 | 整个文档 |

JSONPath 必须填写。切换查询语法时会重置该语法的默认路径，因此切换后请重新确认路径。

## 结构对比

选择「结构对比」，将旧 JSON 放入源输入、新 JSON 放入对比输入。执行后查看新增、删除、修改数量，再用「路径 / 高亮 / 文本」阅读明细。结构对比按 JSON 的结构工作，普通文本逐行差异请用[文本对比](../tools/text-diff.md)。

例如把 `{"version":1}` 与 `{"version":2,"enabled":true}` 对比，可看到版本修改和新字段增加。

## Schema 校验

选择「Schema 校验」，在第二输入放入规则，例如：

```json
{
  "type": "object",
  "required": ["name"],
  "properties": {"name": {"type": "string"}}
}
```

`{"name":"DevKit"}` 符合该规则，`{"name":42}` 则不符合字符串类型。结果以中文解释原因，并高亮数据与对应规则；缺失字段时标记所属对象。当前支持 Draft 2020-12，不能把“任务执行完成”视为“校验通过”。

## TypeScript 类型

选择「TypeScript 类型」，填写根类型名称，例如 `ApiResponse`，再执行。从样例推断的类型只能反映这份数据；可选字段、业务枚举和其他响应形态仍需按接口约定补充。

## 在终端使用

```sh
devkit run json --input-file response.json --option operation=minify --format text
devkit run json --input-file response.json --option operation=query --option 'path=$.users[0].name'
devkit run json --input-file old.json --secondary-file new.json --option operation=diff
devkit run json --input-file response.json --secondary-file schema.json --option operation=schema
```

完整参数见 [JSON 工具参考](../tools/json.md)，复杂输入见 [CLI 与 AI](../cli-and-ai.md)。
