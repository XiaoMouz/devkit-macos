# 开发与维护

## 构建

`project.yml` 是 Xcode 配置源，工程随仓库保存。最低部署版本为 26.0。本次环境为 macOS 27.0.1、Xcode 27、Apple Silicon；最低版本和 Intel 不等于已实机验证。

用户指定：构建、验收、签名、归档与发布统一使用 Xcode。打开 `DevKit.xcodeproj`，选择 `DevKit` scheme 和 `My Mac`；日常按 `⌘R` 运行 Debug，发布时选择 `Product → Archive` 构建 Release，在 Organizer 的 Archives 中通过 `Distribute App` 完成签名、导出或上传。

交互验收仅使用 Xcode 当前启动的应用，不并行启动安装版、其他构建目录的 App 或独立身份的预览副本。外置构建、打包、重签名、路径定位和旧注册清理脚本已移除；不再维护第二条发布流水线。Xcode 工程内的 `Embed worker` 构建阶段负责把 helper 放进应用包，属于正常 target 构建依赖。

签名由 Xcode 的 Signing & Capabilities 和 `Config/Signing.xcconfig` 管理，本机团队配置保存在不入库的 `Config/Signing.local.xcconfig`。不通过外部脚本挑选证书或重签名。

## 应用图标

图标的唯一源文件是 `DevKit/Resources/AppIcon.icon`，可用 Xcode 自带的 Icon Composer 编辑。三个 SVG 图层分别负责薄荷绿模块、带反光的括号和玻璃侧边；不再维护 PNG AppIcon 资源集或旧的 Swift 绘图脚本。

使用 XcodeGen 2.46 或更新版本生成工程，`.icon` 会作为 `wrapper.icon` 加入 Resources，目标的 `ASSETCATALOG_COMPILER_APPICON_NAME` 保持为 `AppIcon`。Xcode 构建时负责生成系统所需图标资源，详见 [Apple Icon Composer 接入说明](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)。

在 Icon Composer 中检查默认、深色、单色及小尺寸效果，最终图标资源由 Xcode 构建生成。图标验收使用同一 Xcode Run 产物。

## 编辑器语法资源

`Vendor/syntax.mjs` 注册离线语法并将 highlight.js 的安全标记结果转换为 UTF-16 token 范围；运行 `node Vendor/build.mjs` 更新 `Resources/syntax.js` 和第三方许可证。文本只作为解析数据传入 JavaScriptCore。`SyntaxLanguage` 负责工具模式/MIME 路由，`SyntaxHighlighter` 在后台串行解析，`CodeEditor` 使用临时布局属性着色。新增语法时同步注册、语言枚举和 `SyntaxHighlightingTests`。

运行 `Scripts/test-editor.sh` 可在独立隐藏窗口验证原生编辑器的选区、撤销、复制、组合文本、折行及深浅色；脚本先构建 Swift Package，再编译实际编辑器源码，使用独立粘贴板，不修改当前应用会话。

## 新增模块

在 `Sources/DevKitCore/Tools/<id>/` 中声明 `ToolModule`。小模块的 `Options`、字段定义和引擎可以同文件；复杂逻辑按职责继续拆分。`Options` 是模块自己的 `Codable & Sendable` 类型，字段通过可写 KeyPath 连接原生 UI。

`ToolMetadata` 定义 ID、名称、分类、说明、示例、输入布局和是否显式联网。`execute` 接收不可变输入快照，返回文本、条目、二进制附件或受限 HTML 预览，不能读取剪贴板或 UI 状态。

修改后执行 `python3 Scripts/update-registry.py`、`xcodegen generate` 和 `swift test`。JavaScript 的 `Engine.mjs` 与模块 Swift 文件放在同一目录；新增时在 `Package.swift` 排除该脚本，运行 `node Vendor/build.mjs` 更新离线 bundle。公共逻辑放在 `Shared` 或 `Vendor` 共享源中。

专属 UI / App Intents 置于 `DevKit/Tools/<id>/`。WebSocket 使用专属会话视图；其余工具复用转换、双输入、生成或文件布局。

## 执行与取消

主窗口将请求通过标准输入交给包内 `DevKitWorker`，不使用 Shell 字符串。工作进程通过 JSON 返回结构化结果和错误，输入不出现在进程参数中。

父进程在取消或 24 秒截止时终止 helper；helper 另有 25 秒墙钟 alarm 和 15 秒 CPU 限制。这是可终止的工作进程，不是操作系统安全沙箱，也不宣称严格的内存硬上限。DNS 使用固定绝对路径与参数数组，查询自身有 3 秒超时。

每个标签用输入版本校验结果。修改会取消任务并标记旧结果无效，过期任务不能覆盖新结果。仅持久化偏好与工具 ID，不保存内容。

## 依赖与许可证

运行时使用系统 Foundation、CryptoKit、Security、ImageIO、CoreImage、Vision、JavaScriptCore、WebKit 和 zlib。复杂格式使用成熟的本地解析器，不执行输入程序，不通过 CDN 获取代码。

`Vendor/package.json` 与锁文件固定版本。构建脚本收集直接及间接依赖许可证至 `Sources/DevKitCore/Resources/ThirdPartyNotices.txt`；`Vendor/licenses/boolbase-LICENSE` 补充 npm 包缺少的上游文本。

主要组件包括 Prettier 3.9.9、Ajv 8.20.0、YAML 2.9.1、smol-toml 1.9.1、lossless-json 4.3.1、JSONPath Plus 11.2.0、Terser 5.51.2、CSSO 5.0.5 和 SVGO 4.1.0；全部准确版本以锁文件为准。Node.js 仅用于构建，不随应用分发。

修改依赖后同时更新 bundle、许可证，并执行格式、精度、预览和超时测试。

## 发布所需外部条件

正式签名需要开发者自己的证书和 Team ID；公证需要对应账号。发布渠道、收费策略、源代码许可证仍由产品所有者决定。没有凭据时不能宣称已完成 Apple 公证。


## 工作区与多窗口

`DevKit/Shared/ToolSession.swift` 是常规工具会话的单一数据源；主标签与独立窗口直接引用它。`DetachedWorkspaceWindows` 管理原生窗口，按会话 ID + 面板类型复用。窗口级命令按当前窗口分发，不将独立窗口的关闭动作路由到主标签。

`DevKitSession` 是同源的 Swift Package 测试目标，只包含会话、桥接及执行服务代码，供 `DevKitSessionTests` 验证异步和生命周期；应用仍由 Xcode target 编译。测试可注入执行器，生产默认使用包内工作进程。关闭标签与最后一个独立窗口时才取消会话任务。

## 测试与产物检查

`Scripts/` 保留工具注册表维护、编辑器/外观回归、worker 集成测试与 Spotlight 元数据检查。`integration-tests.py` 和 `check-spotlight-metadata.py` 显式接收 Xcode 构建出的 App 路径，不定位、构建、安装或启动其他版本。

应用自身的工具索引通过“设置 → Spotlight → 清空索引并关闭”管理。静态 App Intents 由系统管理；测试时复用原 bundle ID，不创建带同名动作的应用副本。

历史重复包的 ZIP 备份保留在已忽略的 `build/retired-spotlight-apps.noindex/` 中，日常验收不恢复或启动这些旧包。

## 窗口结构与 Liquid Glass

主窗口使用系统容器布局：`NavigationSplitView` 负责侧栏栏位、收放与工具栏标题位置，侧栏栏位内用 `floatingSidebarPanel()` 绘制内缩的悬浮 Liquid Glass 面板（栏位先铺窗口底色，不依赖系统是否把侧栏画成悬浮样式），搜索使用面板内的原生 `NSSearchField`；统一样式的窗口工具栏承载标题、主操作和视图切换，`.inspector` 承载右侧配置。红绿灯、侧栏收放按钮、工具栏玻璃分组、滚动边缘效果和收放动画仍由系统负责，并跟随系统的 Liquid Glass、减少透明度和减少动态效果设置。

工具会话在后台保持挂载，以保留输入和结果。每个工具视图通过 `\.workspaceActive` 环境值判断自己是否可见，只有可见工具向窗口工具栏提供“输入 / 结果 / 对照”切换和窗口菜单；独立窗口没有共享工具栏，仍在内容顶部显示这些控件。

应用不读取或写入任何 Liquid Glass 的私有偏好，也不提供自定义透明度；设置中只保留浅色 / 深色主题。`Scripts/test-appearance.sh` 验证主题在多个窗口和原生文本编辑器中的传播。

## Spotlight 的开发签名要求

2026-10-10 本机 `linkd` 日志显示 `Unable to get teamId from app.devkit.macos`，随后 `Rejecting invalid client due to requiresValidatedBundle`，对应系统 UI 的“快捷指令无法与 App 通信”。动作目录发现与实际 IPC 运行是不同阶段；这是签名身份缺失，不能靠重建索引、修改 Base64 参数或让用户重复绑定解决。

在 Xcode 中选择有效的开发团队与 Apple Development 签名；Archive 的分发签名、公证或上传在 Organizer 中根据渠道配置。没有所需证书时先修复 Xcode 账户及签名设置，不通过外部脚本覆盖或伪造签名。

设置页读取运行进程的真实签名；无 Team ID 时会提示系统执行受阻。`Scripts/check-spotlight-metadata.py` 只验证动作描述，不替代系统通信与执行验证。

若 Xcode 已创建证书，但 `security find-identity -p codesigning` 能看到身份而 `-v` 仍显示 0 个有效身份，应检查证书有效期、私钥与 WWDR 中间证书链，不要反复创建证书。当前 Apple Development 证书使用 WWDR G3；可从 [Apple PKI](https://www.apple.com/certificateauthority/) 获取签发者对应的官方中间证书并验证，再安装到登录钥匙串。不要设为“始终信任”来掩盖链验证错误。签名成功后的通信证据应包含 `linkd` 接受应用的 autoShortcut / mediator 连接，而非仅存在动作元数据。
