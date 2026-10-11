# 验收问题修复与复验

> 归档说明：本文件保留验收结论。截图、日志、采样和中间产物已移至仓库外；“归档”路径相对于原报告所在目录。详见[资料管理说明](../../README.md)。

2026-10-11，DevKit / My Mac / Xcode Run。**已修复本轮确认的功能缺陷并完成针对性实机复验；100 MB 内存目标仍未关闭，不能标记“全部问题已解决”。** 原始问题见[补测报告](../expanded/report.md)，本目录保留修复迭代与最终证据，不覆盖修复前结论。

## 已修复及证据

| 问题 | 最终处理 | 验证 |
| --- | --- | --- |
| 数字格式小数精度丢失 | Decimal 舍入后直接格式化十进制数字，避免 NumberFormatter 的浮点转换 | 20 位小数与快捷键（归档：`evidence/fixed-decimal-latest-shortcut.txt`） |
| 多行 Cookie 被合并 | 逐条解析 Set-Cookie，保留 Expires 的逗号 | 多行结果（归档：`evidence/fixed-cookie-multiple.txt`） |
| 正则 10000 边界、v 模式零宽 | 恰好 10000 条允许，超过才拒绝；Unicode 零宽正确前进 | 真实 10000 匹配（归档：`evidence/fixed-regex-10000.txt`），核心回归 |
| 短结果左端裁切、沿用滚动 | 行号独立于滚动容器，结果版本变化重置选区与滚动 | 短结果画面（归档：`evidence/fixed-gutter-short-result.png`）、大到小（归档：`evidence/fixed-gutter-large-to-short.png`） |
| QR/缩进/CSS 参数显示与执行不一致 | 执行前统一整数范围校验；CSS 引擎同时校验声明范围 | QR（归档：`evidence/fixed-qr-range.txt`）、CSS（归档：`evidence/fixed-css-range.txt`） |
| 隐藏毫秒与公元 1 年偏差 | 毫秒可见；编辑秒时归零；历史解析、显示、ISO 统一延伸公历 | 公元 1 年（归档：`evidence/fixed-year-one.txt`）、编辑秒（归档：`evidence/fixed-date-second-output.txt`） |
| 时区菜单难查找、DST 口径不明 | 城市/标识/偏移搜索，精确 UTC 优先；日期与 Cron 展示 DST 规则 | UTC 搜索（归档：`evidence/timezone-search-utc-final.png`） |
| WebSocket 正常关闭误报错误 | 区分 1000/1001 与异常关闭，保留 code/reason | 远端正常关闭 1000（归档：`evidence/fixed-ws-close-start.txt`） |
| Mock 字段错误损坏草稿、列顺序不一致 | 用有序行数据保存草稿，独立校验空名/重名/类型和种子范围 | 切回草稿（归档：`evidence/fixed-mock-return.txt`）、恢复生成（归档：`evidence/fixed-mock-recover.txt`） |
| JWT 数组被接受、时间声明不明确 | Header/Payload 必须对象，NumericDate 类型校验，签名与 exp/nbf 独立显示 | 结构（归档：`evidence/fixed-jwt-object.txt`）、时间（归档：`evidence/fixed-jwt-temporal.png`） |
| 非法 IPv6 主机被接受 | 校验括号内 IPv6 与网络方案主机 | 实际错误提示（归档：`evidence/fixed-url-ipv6.txt`） |
| 失败仍显示旧结果计数、导入失败后误跑旧输入 | 失败清除旧结果；导入失败阻止执行，提供显式继续按钮 | 错误状态（归档：`evidence/final-error-clears-result.png`）、导入阻止（归档：`evidence/final-import-blocked.png`）、确认继续（归档：`evidence/final-import-acknowledged.txt`） |
| 图片预览缺信息、压缩增大仍普通成功 | 展示尺寸/文件体积；增大与目标未达显示警告 | 70→777 字节（归档：`evidence/fixed-compress-warning.png`）、4K 目标未达（归档：`evidence/guard-4k-result.png`） |
| 对比度阈值显示误导 | 4 位精度，阈值附近说明，补 AAA 大字 | #959595（归档：`evidence/fixed-contrast-threshold.txt`） |
| 文本换行不一致 | LF、CRLF、CR、NEL、LS、PS 统一计数 | CR/LS（归档：`evidence/fixed-lines-cr-ls.txt`） |
| 错误不清楚 | 图片损坏/不支持与像素超限分开；QR 纠错级别容量、CSS/HTML 容错、parser 与网络错误提示；HTTP 状态英文名使用明确注册表 | 坏图（归档：`evidence/fixed-invalid-image-message.txt`）、HTTP 超时（归档：`evidence/fixed-http-timeout-complete.txt`），核心回归 |
| 文件校验 32 MiB 上限 | 后台流式 1 MiB 分块，不进入 worker JSON；进度、取消、读取中修改检测 | 33 MiB 摘要（归档：`evidence/stream-33m.txt`）、8 GiB 进度（归档：`evidence/final-checksum-progress.png`）、取消（归档：`evidence/final-checksum-cancel.txt`） |
| Favicon 逐个导出 | 全部导出到唯一子目录，后台写盘，原生 sheet | 7 个产物批量导出（归档：`evidence/fixed-favicon-export-all.txt`）、[独立尺寸/ICO 读回](favicon-batch-readback.json) |

## 大文本、预览与资源处理

- 超过 131072 UTF-16 单元按 32768 单元分段显示/编辑，页边界不拆代理对。编辑只替换本段；计算、复制和导出仍用全文。取消旧的 50 万字符结果截断。长行禁用自动折行，避免 CoreText 对巨大段落反复排版。
- 分段切换清理本段撤销记录；大粘贴可撤销/重做。仅挂载可见面板，销毁原生编辑器时释放文本、撤销和高亮任务。特别保护 SwiftUI 切换分支期间的旧 binding，避免已进入分段模式的全文短暂流入旧 TextKit 视图。
- 跨段修改（归档：`evidence/paged-edit-second.txt`）保留尾部；5 MiB 加 1 字节正确触发上限；大粘贴撤销（归档：`evidence/large-paste-undo.txt`）/重做（归档：`evidence/large-paste-redo.txt`）成功；1 MiB 完整复制解码（归档：`evidence/guard-base64-roundtrip.txt`）得到 1048576 字符。
- 图片缩略图在后台串行解码，只保留适合显示的 CGImage；高亮 JavaScript VM 空闲释放；worker 请求处理有 autoreleasepool；释放大资源后用公开 allocator API 回收空闲页。
- WKWebView 最多保留一个短时闲置实例，10 秒释放。保持禁用 JavaScript、CSP、导航限制和非持久数据存储。增加创建/复用/加载/失败/退出日志，一次自动恢复及后续手动重载。
- 五轮预览切换（归档：`evidence/preview-pool-five-switches.txt`）复用同一个已确认 PID；真实终止注入（归档：`fault-injection.jsonl`）验证自动恢复以及第二次终止后的手动重载（归档：`evidence/preview-manual-reload.txt`）。仅终止属于合成验收内容的已确认 WebContent 进程。

## Xcode 与实际操作结果

- Xcode **DevKitCore 90 项通过**、**DevKitSessionTests 15 项通过**：核心报告（归档：`evidence/core-tests-final.txt`）、会话报告（归档：`evidence/session-tests-final-paging.txt`）。新增 16 项核心回归覆盖精度、边界、草稿、日期、流式读取/取消/修改检测及分段完整性。
- 本轮修复期间 48 个工具均逐一做过实际主流程 smoke，记录在 actions.jsonl（归档：`actions.jsonl`） 的 `smoke-工具名`。最后共享编辑器调整之后又复验大文本/复制/撤销、JSON、源码、图片、文件校验、时区和错误恢复；没有把旧版 719 个证据 ID 宣称为全部在最终构建上重新执行。
- 最终方案 DevKit / My Mac，Xcode 启动 PID **54188**，仍在运行。没有命令行构建/启动另一份 App，没有改签名配置。`git diff --check` 通过。Vendor bundle 从源模块重新生成。
- 最终实测：5 MiB 文本全文统计 **545 ms**；1 MiB Base64 往返解码 **1.0 s**；3000 行 JavaScript 格式化 **2.3 s**；4096×4096 图片压缩 **508 ms**。这些是界面显示的执行耗时，不包含完整输入到首帧延迟；源码格式化仍有可感知等待，但在隔离 worker 中运行并可取消。
- 记录包括操作预期和中间状态；`expected` 不是自动通过标志。异步任务以 `*-complete`、`*-result` 或报告列出的最终证据为准。初期记录路由修正见 说明（归档：`evidence-routing.md`）。临时样本服务和资源采样器已停止。

## 内存结论：改善明确，100 MB 目标未通过

同机 Debug 环境，M3 / 16 GiB / macOS 27.0.1。不能把 RSS、Xcode footprint、应用和子进程相加后当作同一种指标。

| 观察 | 数值及证据 |
| --- | --- |
| 原验收长期清理后 | Xcode 379.4 MB，RSS 270.09 MiB，见[原报告](../expanded/report.md) |
| 修复中 48 工具轻量 smoke 后 | footprint 135.9 MB、heap 86.7 MB，见 heap（归档：`heap-after48.txt`） |
| 分段过渡保护前压力后 | footprint 284.8 MB、heap 255.9 MB，其中字形 advances 180 MB，见 heap（归档：`heap-final-stress.txt`）、持有关系（归档：`glyph-final-owner.txt`） |
| 最终构建压力与负向路径后内存图 | footprint 179.0 MB、进程峰值 230.0 MB；heap 87.9 MB，其中字形 advances 1952 KiB，见 heap（归档：`heap-guard-stress.txt`） |
| 最终空闲 | Xcode **155.3 MB**、CPU 0%，RSS **130.72 MiB**，见 Xcode（归档：`evidence/log-final-build.txt`）、[汇总](resource-final-summary.json) |
| 最终采样峰值 | 主进程 RSS 284.00 MiB，可追踪主进程与 worker 合计 RSS **531.41 MiB**；不是完整多进程 footprint，也不能声称峰值已经整体下降 |

最终负载顺序和原版全部子模式序列不同，不据此计算严格优化百分比。约 0.5 秒采样可能漏过瞬时峰值；部分 WebKit GPU/Network/短命子进程未跟踪；阶段标签有持续到后续操作的情况，最终汇总按 PID 和时间段计算。原始 CSV（归档：`process-samples.csv`） 保留。

大文本字形缓存膨胀已有明确修复证据；100 MB 总目标仍未实现。剩余 heap 包含约 45.8 MB 未分类分配、Swift/SwiftUI/CoreSVG 元数据和系统缓存，不能把整个 footprint 差额武断定性成泄漏。没有用重启后的 73.5 MB 冷启动值代替使用后结果，也没有靠丢弃用户输入来降低读数。

## 警告处理与仍需保留的边界

最终原始日志（归档：`evidence/log-final-build.txt`）仍可看到 WindowServer pid 608 的 task-name port、ViewBridge Code 18、WebContent sandbox/XPC/私有资源诊断。已定位相关系统进程/模块，并用预览正常加载及故障恢复对照，**没有证据支持把它们全部称为 DevKit 崩溃，也没有证据支持全部判定无害**。

原生面板改成 sheet，修复轮重复导入、取消、保存、批量导出没有再次捕获原来的 Animation 时间倒退/deferral 日志；原告警没有完整符号化根因，仍保留复现边界。WebKit 创建、复用、释放日志已能关联具体工具。没有静音 stderr/系统日志，没有关闭 sandbox，没有添加私有 entitlement。

因此，本次可关闭上述已复现的功能错误和大文本缓存膨胀原因；**100 MB 性能门槛、系统诊断的全部根因及原 Animation 偶发日志的彻底排除继续开放**。本次没有发布、归档或推送代码。
