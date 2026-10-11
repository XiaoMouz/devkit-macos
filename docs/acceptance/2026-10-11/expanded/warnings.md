# 用户粘贴警告的逐类核对

> 归档说明：本文件保留验收结论。截图、日志、采样和中间产物已移至仓库外；“归档”路径相对于原报告所在目录。详见[资料管理说明](../../README.md)。

原文已保存为 warnings-original.txt（归档：`warnings-original.txt`），共 446 行；归一化重复统计见 warning-counts.txt（归档：`warning-counts.txt`）。这是诊断记录，**没有将整批日志判为可忽略，也没有通过关闭日志或增加私有权限来消除输出**。

## 解锁后完成的隔离对照（最终更新）

本节更新早期表格中的“待复核”状态；原始警告仍保留，未声称全部根因已定位。48 工具子模式与极端输入补测已完成到[最终实操报告](report.md)所列范围。

- 恢复段普通文本基线（归档：`evidence/log-isolated-base64.txt`）：清空已保存的控制台后执行 3 次 Base64，没有新增 WebContent 或匹配警告。
- SVG 预览入口（归档：`evidence/log-svg-preview-entry.txt`）：出现 WebContent PID 9512 及同组 sandbox/XPC 诊断。清空控制台后，在同一现有预览中重新执行，先仅截图读取 Xcode，再读取应用 AX；读 AX 前（归档：`evidence/log-svg-before-app-ax.txt`）与读 AX 后（归档：`evidence/log-svg-after-app-ax.txt`）均没有新增。这个对照没有新建预览实例，不能排除新建实例时的无障碍影响。
- 五轮文本/预览切换（归档：`evidence/log-svg-five-recreates.txt`）：额外出现 9639、9646、9654、9661、9668 五个 PID，预览实际仍正常。这再次支持重复诊断与实例/进程生命周期相关。日志 AX 快照含控制台和聚焦元素的重复文本；工具当时打印的 44/238 是正则匹配次数，**不是去重后的真实警告条数**。
- 打开/保存面板取消（归档：`evidence/log-file-panels-cancel.txt`）没有在已有输出上新增这组匹配警告。ViewBridge Code 18 没有由这个小对照单独复现，原始来源继续保留未确认。
- 恢复段日志（归档：`evidence/log-resumed-images.txt`）捕获到 AppKit / Animation 分类的主进程 47490 警告，时间为 2026-10-11 14:02:35.448986 +08:00，timeStamp 222305.842887、timeLastStepped 222306.178562，相差约 **335.675 ms**。可见片段有多条相同时间对，首行从上一条中间开始，不据此推断精确总次数。
- 操作时间线中，14:02:34.125 已切到 ICO 预览，14:02:38.810 完成 ICO 保存，警告落在此间。三次单独重复 ICO 导出（归档：`evidence/log-isolated-favicon-export-three.txt`）没有重现。当前只能关联到该次保存面板操作时段，不能认定 SVG、某一个 SwiftUI animation 或锁屏恢复就是根因。
- WebSocket 的正常远端关闭已复现 UI 错误显示，见记录（归档：`evidence/ws-remote-close.txt`）；它与原始单条 nw_socket 日志是否为同一原因仍无完整连接映射。
- 解锁后的截图、AX、导出产物与两段采样均已保存，临时样本服务和采样器已停止，Xcode 中的 DevKit 仍在运行。没有通过清理 Console 删除原始证据，也没有屏蔽新的日志。

建议将预览实例创建、销毁、导航失败、内容进程终止，与工具 ID、单调时间和生命周期原因关联记录；对动画警告增加保存面板前后符号化调用栈证据。正常取消日志可以分类，但不能靠静音整个 WebKit/AppKit 日志来宣称修复。

## 当前能确定的结论

| 日志组 | 原文中的规模 | 本机证据与判断 | 处理状态 |
| --- | ---: | --- | --- |
| `Unable to obtain a task name port right for pid 608` | 1 条 | 本机 `ps` 确认 PID 608 是 WindowServer，不是 DevKit 或工具 worker。日志表示无法取得该进程的 task-name port，不能据此推断 DevKit 已崩溃 | 未发现对应功能中断；调用来源仍未定位，保留诊断 |
| `ViewBridge … Code=18 / NSViewBridgeErrorCanceled` | 1 条 | 日志自身标记为 remote view controller 连接取消。上轮文件面板有打开/关闭操作，但原文缺少时间戳，不能精确归到某一次面板关闭 | 需要单独复核文件面板取消；不把文字里的 “benign” 当作本次全部无害的证据 |
| WebContent 的缺失资源与 sandbox/XPC 拒绝 | 6 个 WebContent PID；`Couldn't open <private>` 120 条、`DoNotConnectToServerMask` 78 条、无效连接 ID 54 条 | 同一组日志在每个预览子进程中重复。包含 pasteboard、TCC ListenEvent、Launch Services、CoreServices、AudioComponentRegistrar 等服务访问失败，来源是 WebContent，不是用户输入的解析错误 | 已复现与 WebKit 预览创建有关，尚不能确认其中哪些来自系统、调试环境或无障碍观察触发；不能笼统标记为产品崩溃或完全无害 |
| WebContent 的 linkd / App Intents entitlement 警告 | 6 组 | 每组都由 `WebContent[PID]` 输出。它并不能证明 DevKit 主应用的 Spotlight 签名或 entitlement 失败 | 不向应用添加 `com.apple.linkd.*` 或 `com.apple.runningboard.assertions.webkit` 私有权限；如查 Spotlight，应另查主应用 PID 与系统链路 |
| `markAllLayersVolatile` / `XPCConnectionTerminationWatchdog` / target process does not exist | 5 次 layers 提示；多条成对 assertion 诊断 | 与 WebKit 进程释放/退出相关。切换预览与文本会销毁/重建当前 WKWebView；“目标不存在”也可能是退出期间的竞态。原日志没有 `reason=Crash`、`processDidTerminate`、`EXC_BAD_ACCESS`、`SIGABRT` 明确标记 | 需要退出原因与恢复行为的证据，不能单凭 assertion 文本说“崩溃”，也不能据此排除子进程异常 |
| `Animating backwards in time!` | 4 条；同一对时间戳 | 记录的动画时间比上次步进时间倒退约 149.823 ms。这是动画时序异常，和非法业务输入不是一类问题 | 原文未提供触发窗口/堆栈。仍需针对切换/布局/窗口操作复现，未关闭动画来掩盖 |
| `nw_ws_validate_server_response … HTTP/1.0` / `NSURLErrorDomain -1011` | 1 次握手 | 明确来自上轮本机样本服务 `ws://127.0.0.1:18765/echo`。服务最初返回 HTTP/1.0，修正为 HTTP/1.1 后，同一个 DevKit 实例已完成收发、切换后继续收发及断开 | 已归因为验收服务，不是产品握手实现错误；该失败本身正确展示了服务响应错误 |
| `nw_socket_output_finished … Socket is not connected` | 1 条 | 处于上述网络操作附近，可能是已经断开的连接执行 shutdown；原文无足够时间/连接映射 | 不能据此推断活跃连接丢消息，待网络异常分支核对 |
| `Handled error from server: Connection interrupted` | 1 条 | 没有进程、服务、时间戳，不能确定是文件服务、预览还是其他 IPC | 来源待定位，保留原文，不宣称已解决 |

## 本轮控制台隔离实测

没有重新构建或启动另一份 App。当前仍为 Xcode Run / Debug 的 DevKit PID 47490。

1. 先保存 清空前控制台（归档：`evidence/xcode-before-expanded.txt`），通过 Xcode 的 Clear Console 清空显示；原始证据未删除。
2. 执行 Base64 标准/URL Safe、保留/移除填充等纯文本操作。新控制台没有 WebContent PID，没有上述匹配到的告警：纯文本基线（归档：`evidence/log-plain-base64.txt`）。
3. 进入 JSON 格式化和校验的预览，再切换结果模式。新增 WebContent PID 57469、57514，重复诊断出现：预览创建记录（归档：`evidence/log-json-preview-created.txt`）。
4. 执行 JSON 结构对比、Schema 的成功/失败与预览，进一步新增 PID 57824、57900：全部 JSON 功能记录（归档：`evidence/log-json-all-modes.txt`）。
5. 后续哈希、生成器、数值换算没有新增 WebContent PID：后续控制台（归档：`evidence/log-after-conversion-matrix.txt`）。这支持“该批重复日志与预览生命周期有关”，不等同于已确定每条系统拒绝的根因。

已检查当前用户 DiagnosticReports 目录中带 2026-10-11 日期、名称包含 DevKit/WebContent/WebKit 的报告，未找到匹配项：检查记录（归档：`diagnostic-report-inventory.txt`）。报告可能不生成、位于其他位置或命名不同，因此这不是“从未崩溃”的证明。

## 代码中可确认的诊断缺口

`DevKit/Shared/SafePreview.swift` 每次创建 WKWebView 时配置独立的 `nonPersistent()` data store，并实现导航拦截；目前没有实现内容进程终止、导航失败的可见错误状态或有界恢复。源码审阅不能替代故障注入，但它解释了为什么现有日志不足以区分正常销毁与异常退出。

Apple 官方说明 Web 内容在独立进程中运行，可通过 `webViewWebContentProcessDidTerminate(_:)` 获知终止；`nonPersistent()` 的含义是不把网站数据写入磁盘，不代表不使用内存或不会创建进程。参考：[进程终止回调](https://developer.apple.com/documentation/webkit/wknavigationdelegate/webviewwebcontentprocessdidterminate(_:))、[非持久数据存储](https://developer.apple.com/documentation/webkit/wkwebsitedatastore/nonpersistent())。

建议补充公开 API 层的预览加载/失败/退出日志（工具、预览实例、时间、原因），并在异常退出时提供重载入口和有限次数恢复；再以相同 UI 路径比对进程数量、内存与告警。不要通过忽略 stderr、禁用 sandbox 或加入系统私有 entitlement 来掩盖问题。本轮尚未修改产品源码。

## 中途锁屏记录

继续进入 Cookie 工具时，桌面控制服务曾返回：`The Mac is locked and automatic unlock could not unlock it.` 已请求用户手动解锁。随后重新读取桌面成功，已经恢复补测；锁屏期间只整理记录，没有把未执行操作计入完成。

恢复后又完成了网络及大部分图像模式；随后再次锁屏，连读取桌面也返回相同失败，已再次请求解锁。此中断来自桌面访问条件，不是 DevKit 计算错误。

## 网络负向操作新增日志的解释

本轮真实发起无响应请求、重复头、非HTTP方案、不可信本地证书、WebSocket数量/体积超限和远端关闭。对应超时、证书、断线日志属于这些已明确触发的负向操作，需要与原始未归因警告分开看。不能用它们新增的错误行数判断应用变得更不稳定。

有效HTTPS请求已成功；有效WSS使用 [Postman官方Echo端点](https://learning.postman.com/docs/developer/echo-api) 完成 `DevKit acceptance ping` 的发送与原样回显后主动断开；只发送非敏感样本文本。证据见 wss-public-echo（归档：`evidence/wss-public-echo.txt`）。网络操作后的控制台（归档：`evidence/log-network-complete.txt`）已保存。
