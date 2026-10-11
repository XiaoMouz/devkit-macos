# 工具目录

工具按 9 类组织，共 48 个注册入口。编码/解码和同类算法作为工具内部选项，JSON 的八种操作共用一个工作台。具体子能力见[实现与边界](implementation-status.md)。

## 编码与转换

| ID | 工具 |
| --- | --- |
| `base64` | Base64 |
| `url-codec` | URL 编解码 |
| `data-url` | Data URL |

## 结构化数据

| ID | 工具 |
| --- | --- |
| `json` | JSON 工作台 |

## 摘要与令牌

| ID | 工具 |
| --- | --- |
| `hash` | 哈希摘要 |
| `hmac` | HMAC |
| `file-checksum` | 文件校验 |
| `jwt` | JWT 工作台 |
| `pem-certificate` | PEM 与证书 |

## 标识与测试数据生成

| ID | 工具 |
| --- | --- |
| `random-string` | 随机字符串 |
| `uuid` | UUID |
| `ulid` | ULID |
| `nanoid` | Nano ID |
| `mock-data` | Mock 数据 |
| `qr-code` | 二维码 |

## 文本与匹配

| ID | 工具 |
| --- | --- |
| `text-diff` | 文本对比 |
| `text-case` | 命名与大小写 |
| `text-lines` | 文本行处理 |
| `text-stats` | 文本统计 |
| `regex` | 正则测试 |
| `text-replace` | 文本查找替换 |
| `markdown` | Markdown |

## 时间与数值

| ID | 工具 |
| --- | --- |
| `timestamp` | 时间戳 |
| `date-time` | 日期与时区 |
| `cron` | Cron |
| `number-base` | 进制转换 |
| `number-format` | 数字格式 |
| `unit-convert` | 单位转换 |

## Web 与网络

| ID | 工具 |
| --- | --- |
| `url-parser` | URL 解析 |
| `query-string` | 查询参数 |
| `http-status` | HTTP 状态码 |
| `mime-types` | MIME 类型 |
| `cookie` | Cookie |
| `curl-convert` | cURL 转换 |
| `http-client` | HTTP 调试 |
| `websocket` | WebSocket 调试 |
| `dns` | DNS 查询 |

## 前端样式

| ID | 工具 |
| --- | --- |
| `color` | 颜色转换 |
| `contrast` | 对比度 |
| `css-unit` | CSS 单位 |

## 代码与图形资源

| ID | 工具 |
| --- | --- |
| `code-format` | 代码格式化 |
| `code-minify` | 代码压缩 |
| `svg` | SVG 工作台 |
| `image-convert` | 图片格式转换 |
| `image-resize` | 图片尺寸 |
| `image-compress` | 图片压缩 |
| `image-metadata` | 图片信息 |
| `favicon` | 网站图标 |

新增工具时更新注册表、实现范围与对应测试。接入步骤见[模块规范](module-specification.md)。
