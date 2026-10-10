# 开发与维护

## 构建

`project.yml` 是 Xcode 配置源，工程随仓库保存。最低部署版本为 26.0。本次环境为 macOS 27.0.1、Xcode 27、Apple Silicon；最低版本和 Intel 不等于已实机验证。

`Scripts/build.sh Debug|Release` 生成工程、构建应用与工作进程、嵌入 helper 并做临时签名。`Scripts/package.sh` 生成 Release ZIP。脚本不安装证书、不上传产物、不发布版本。

## 应用图标

图标的唯一源文件是 `DevKit/Resources/AppIcon.icon`，可用 Xcode 自带的 Icon Composer 编辑。三个 SVG 图层分别负责薄荷绿模块、带反光的括号和玻璃侧边；不再维护 PNG AppIcon 资源集或旧的 Swift 绘图脚本。

使用 XcodeGen 2.46 或更新版本生成工程，`.icon` 会作为 `wrapper.icon` 加入 Resources，目标的 `ASSETCATALOG_COMPILER_APPICON_NAME` 保持为 `AppIcon`。Xcode 构建时负责生成系统所需图标资源，详见 [Apple Icon Composer 接入说明](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)。

运行 `Scripts/export-icon.sh` 可导出默认、深色、单色、小尺寸和 macOS 26 效果，默认写入已忽略的 `build/icon-previews/`。预览 PNG 无需提交，修改图标后需重新构建应用。

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

## 清理本项目的旧系统注册

`python3 Scripts/reset-spotlight-registration.py` 注销本项目路径内的旧 DevKit 与预览副本，保留 `~/Applications/DevKit.app`。如明确需要注销安装副本，可加 `--include-installed`。脚本不清空系统注册数据库，不删除 App 文件，记录在 `build/spotlight-registration-cleanup-latest.json`。

应用自身的工具索引通过“设置 → Spotlight → 清空索引并关闭”管理。静态 App Intents 的目录显示由系统管理；应用开关控制动态工具实体与执行权限。

安装新版 App 应替换整个 bundle，并在替换后运行 `codesign --verify --deep --strict`。不要用旧 Debug 目录覆盖合并 Release bundle，残留资源可能导致封印校验失败。


## Liquid Glass 偏好适配

`GlassPreferences.swift` 隔离系统读取与透明度策略，`WorkspaceGlass` 只调整窗口外壳背景。macOS 27 的数值滑块已在本机确认写入全局 `NSGlassTintAmount`（0 为透明、1 为最浓色调）；这不是公开的 AppKit 偏好契约，所以只读该值，缺失时退回原生材质，不猜测或写入系统设置。系统模式的可见窗口每秒刷新一次，并在应用激活、辅助功能变化时刷新；自定义模式停止系统轮询。跨版本发布前应在目标系统验证这条适配路径。

`glassMode` 保存模式，`glassTransparency` 继续保存既有通透度，磨砂强度滑块通过 `1 - glassTransparency` 绑定。导航区域始终使用一个完整的 `NSGlassEffectView.Style.regular`，并保留语义侧栏材质的最低覆盖；滑块只增加补充磨砂。使用随有效外观解析的中性原生 tint 保护亮背景上的文字。正常范围内不使用 `.clear`，不把玻璃层淡出到透明，也不添加纯色覆盖；仅在系统“减少透明度”开启时使用不透明辅助功能背景。

材质选择依据 [Apple Materials](https://developer.apple.com/design/human-interface-guidelines/materials)：Regular 会调整背景亮度和模糊程度以维持文字可读性，Clear 主要面向富媒体上的亮色大控件。运行 `Scripts/test-appearance.sh` 验证实际原生视图在滑块两端及中间值都保留 Regular 材质，覆盖偏好刷新、减少透明度和外观切换。


## Spotlight 的开发签名要求

2026-10-10 本机 `linkd` 日志显示 `Unable to get teamId from app.devkit.macos`，随后 `Rejecting invalid client due to requiresValidatedBundle`，对应系统 UI 的“快捷指令无法与 App 通信”。动作目录发现与实际 IPC 运行是不同阶段；这是签名身份缺失，不能靠重建索引、修改 Base64 参数或让用户重复绑定解决。

`Scripts/sign-app.py` 统一签名策略：自动选择唯一有效的 Apple Development、Mac Developer 或 Developer ID Application 身份，存在多个时通过 `DEVKIT_SIGNING_IDENTITY` 指定 SHA-1；无身份时明确标记 ad-hoc 预览。`DEVKIT_REQUIRE_SPOTLIGHT=1 Scripts/build.sh Release` 会在无开发签名时提前失败。签名按 worker、app 的顺序进行，随后验证签名及 TeamIdentifier，不再无条件将已签名构建覆盖成 `-`。

设置页读取运行进程的真实签名；无 Team ID 时提示系统执行受阻，索引状态不再冒充执行可用。不要伪造 Team ID、添加 Apple 私有 entitlement 或关闭系统验证来绕过此要求。证书配置须由用户在 Xcode 账户设置中完成。发布仍另需 Developer ID、公证与目标系统实测。

运行 `python3 Scripts/signing-tests.py` 验证没有证书、唯一证书、多个证书及指定证书的构建策略；`Scripts/check-spotlight-metadata.py` 只验证动作描述，不验证通信。


若 Xcode 已创建证书，但 `security find-identity -p codesigning` 能看到身份而 `-v` 仍显示 0 个有效身份，应检查证书有效期、私钥与 WWDR 中间证书链，不要反复创建证书。当前 Apple Development 证书使用 WWDR G3；可从 [Apple PKI](https://www.apple.com/certificateauthority/) 获取签发者对应的官方中间证书并验证，再安装到登录钥匙串。不要设为“始终信任”来掩盖链验证错误。签名成功后的通信证据应包含 `linkd` 接受应用的 autoShortcut / mediator 连接，而非仅存在动作元数据。
