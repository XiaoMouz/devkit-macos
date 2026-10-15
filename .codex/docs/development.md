# 开发与维护

## Xcode 工作流

遵守根目录 [AGENTS.md](../../AGENTS.md)。打开 `DevKit.xcodeproj`，选择 `DevKit / My Mac`，通过 `⌘R` 运行 Debug；交互验收只使用 Xcode 当前启动的这份应用。

Debug 产物为 `DevKit Debug.app`（`app.devkit.macos.debug`），Release 为 `DevKit.app`（`app.devkit.macos`），同一 DevKit scheme 分别使用 Debug 和 Release 配置。应用名由 `PRODUCT_NAME` 写入 Info.plist，Swift 模块名保持 `DevKit`。两者分别保存语言、工具开关、收藏和索引状态；新 Debug 不自动复制或改写 Release 的偏好。包内 CLI/worker 按当前 bundle 的路径定位，已有 CLI/Skill 安装链接继续遵守冲突保护，不自动改指向 Debug。

归档使用 `Product → Archive`，在 Organizer 中完成分发签名、导出或上传。只有用户明确要求实际发布时才上传。不要添加独立构建、打包、重签名、安装、启动或注册清理脚本。

签名在 Signing & Capabilities 和 `Config/Signing.xcconfig` 中配置；机器私有覆盖放在被忽略的 `Config/Signing.local.xcconfig`。不得覆盖用户团队和证书。若本地包被另一 Xcode 窗口占用，关闭单独打开的 Swift Package，再打开应用工程。

日常开发和分发使用不同团队时，在本机配置中用 `DEVELOPMENT_TEAM[config=Release]` 指定经用户选择的发布团队，保留 Debug 的原有设置。通过 Organizer 的 Direct Distribution 完成 Developer ID 签名和 Apple 公证，再 Export 导出已装订票据的应用。上传 Release 附件前检查签名、Gatekeeper、公证票据与包内辅助程序；压缩现有导出应用时保留签名与扩展属性。不要将本机团队配置写入共享工程。

`project.yml` 是工程结构来源，仅在结构变化时使用 XcodeGen 同步；生成前检查工作区，避免覆盖未提交工程修改。应用图标源为 `DevKit/Resources/AppIcon.icon`，使用 Icon Composer 编辑，由 Xcode 编译。

## 应用内更新与发布 Feed

直接分发的 Release 使用 Sparkle 2.10.0（Xcode Swift Package 依赖，版本固定）。`AppUpdater` 在本次进程首次打开用户界面后启动唯一的更新会话，在应用运行期间默认每天检查并后台下载；仅由 Spotlight 无窗口调起时不启动更新器。完成验证和准备后在窗口底部、应用菜单和「设置 → 更新」提供重启安装入口。也可以正常退出，由 Sparkle 安装已准备好的更新。Debug 不启动更新器，不连接正式 Feed，也不替换 Xcode 产物。用户关闭自动检查/下载后的偏好由 Sparkle 保存，启动时不重置。

`DevKit/Resources/Info.plist` 中的 `SUFeedURL` 指向 main 分支根目录的 `appcast.xml`；更新包仍放在 GitHub Releases。Feed 随 main 分支文件更新生效，不依赖文档站部署。Feed 条目由 Sparkle 官方工具根据实际导出附件生成，包含构建号、最低系统、下载地址、字节数和 EdDSA 签名；不要填写假版本或占位签名。v0.2.0 及更早版本没有更新器，需要手动安装 v0.2.1 一次。

更新包在解压前校验 EdDSA 签名。`SUPublicEDKey` 是可提交的公钥；对应私钥保存在 macOS 登录钥匙串，Sparkle account 为 `app.devkit.macos`，不属于 Apple 签名证书，不能替换 `Signing.local.xcconfig`。妥善备份私钥；不要把私钥、导出文件或钥匙串内容放入仓库、日志和 CI。使用 [Sparkle 官方工具](https://sparkle-project.org/documentation/) 的 `generate_keys --account app.devkit.macos -p` 只查看公钥，发布前与 Info.plist 比对。换机应导入已备份密钥，不重新生成并覆盖公钥；启用解压前验证后，ZIP 更新不能用于丢失旧私钥的密钥轮换。

每次发布：

1. 增加 `CFBundleVersion`（必须严格递增），同步用户可见的 `CFBundleShortVersionString`。在 Xcode `Product → Archive` 和 Organizer 中完成 Developer ID 签名、公证与导出，保持正式 Bundle ID。
2. 用 Finder 压缩 Organizer 导出的 `DevKit.app`，使用稳定的附件名（如 `DevKit-vX.Y.Z-macOS-universal.zip`），将最终 ZIP 放入专用于本次发布的目录。不要修改签名后的应用或重新构建另一份 App。
3. 将现有 `appcast.xml` 复制到该目录。使用与工程同版本的 Sparkle 官方 `generate_appcast` 为现有导出附件生成 EdDSA 签名与 Feed（这是更新元数据生成，不是 App 构建或重签名）：

   ```sh
   /path/to/Sparkle/bin/generate_appcast \
     --account app.devkit.macos \
     --download-url-prefix https://github.com/luolayo/devkit-macos/releases/download/vX.Y.Z/ \
     --maximum-deltas 0 \
     /path/to/release-feed-directory
   ```

4. 检查生成条目的 build/version、最低系统版本、架构、附件 HTTPS 地址、字节数和 `sparkle:edSignature`。初期只分发完整包，关闭 delta 生成。保留历史条目的附件地址，不将历史版本重定向到最新 Release。完成后将生成的 Feed 替换仓库根 `appcast.xml`。
5. **实际上传仍需用户明确要求发布**。先上传完全相同的 ZIP，再将 Feed 发布到 main；确认公开 Feed 与附件可访问。不要发布指向草稿 Release、404 或重新压缩附件的条目。

正式上线前需在已安装的较旧正式版本上验证下载、签名拒绝、重启替换、退出安装、网络错误重试、设置持久化以及 CLI 链接仍有效。完整升级验收涉及正式安装版本，需在明确授权的发布验收中完成；日常 Debug 仅验收界面、禁用状态与编译，不能声称已验证实际替换。

## 核心与会话测试

```sh
python3 Scripts/localization.py --check
DEVKIT_LANGUAGE=zh-Hans swift test
DEVKIT_LANGUAGE=en swift test --filter LocalizationTests
zsh Scripts/test-editor.sh
zsh Scripts/test-appearance.sh
DEVKIT_LANGUAGE=zh-Hans zsh Scripts/test-menu-localization.sh
```

核心与会话测试包含中文报告断言，固定使用 `zh-Hans`；英文行为由独立的本地化回归覆盖，避免测试结果依赖机器语言。编辑器回归编译实际组件，使用隐藏测试窗口和独立粘贴板；它不是另一份 DevKit 验收应用。只修改文档时检查链接和内容即可，不重建应用。

编辑器性能变更可运行 `zsh Scripts/test-editor.sh --benchmark`，测量 100,000 字节中英混合文本的输入与原地刷新耗时。它使用同一隐藏组件测试进程，报告中位数及最大值，不将依赖机器负载的耗时设为测试通过阈值。交互验收仍使用 Xcode 启动的应用。

检查 worker、CLI 和 Spotlight 元数据时，显式传入从 Xcode 获取的应用路径：

```sh
DEVKIT_LANGUAGE=zh-Hans python3 Scripts/integration-tests.py "/path/from/Xcode/DevKit Debug.app"
python3 Scripts/check-spotlight-metadata.py "/path/from/Xcode/DevKit Debug.app"
```

上例使用 Xcode Run 的 Debug 产物；检查归档时传入 Organizer 中实际导出的 `DevKit.app` 路径。

CLI 集成覆盖包内执行、软链接调用、解析器资源、文件和 JSON 输入、附件、错误与超时、受控本地网络。`swift test` 另覆盖参数校验、注册表默认值、安装冲突与隔离临时目录中的 Shell PATH 配置，不改写测试机器的真实启动文件。修改配套 Skill 时同步 `Sources/DevKitCore/Resources/Skills/devkit` 和面向用户的 [CLI 教程](../../docs/cli-and-ai.md)。

## 用户文档站

`docs/` 是中英文 VitePress 手册，中文位于根路径，英文位于 `/en/`。公开教程、首页演示和截图在这里维护；页面结构、组件职责、双语同步与动效约束见[文档站维护](documentation-site.md)。

```sh
npm ci --prefix docs --ignore-scripts
npm run dev --prefix docs
npm test --prefix docs
npm run build --prefix docs
```

依赖与版本以 `docs/package.json` 和锁文件为准。`.github/workflows/docs.yml` 在 main 的文档变更后先测试、构建，再部署 GitHub Pages。缓存和构建产物不入库；日常本地验证不需要推送或部署。

## 翻译资源

新增语言或修改翻译遵循[多语言规范](localization.md)。编辑 `Sources/DevKitCore/Resources/Translations/*.json` 后运行 `python3 Scripts/localization.py`，用 `--check` 检查生成资源是否一致。翻译变更不需要 XcodeGen 或重新打包 JavaScript。

## JavaScript 与资源

仓库已包含运行所需 bundle，普通 Swift 构建不需要 Node.js。修改 JavaScript 引擎或依赖时使用 Node.js 22+：

```sh
npm ci --prefix Vendor --ignore-scripts
node Vendor/build.mjs
```

模块引擎位于各工具的 `Engine.mjs`，共享逻辑位于 `Vendor/`。更新源码时同步 `Sources/DevKitCore/Resources/engines.js`、`syntax.js` 和第三方许可证，保留锁文件。生成文件中的字符串空白有意义，不手动格式化压缩后的 bundle。

`Vendor/syntax.mjs` 注册离线语法，`SyntaxLanguage` 负责工具与 MIME 路由，`SyntaxHighlighter` 串行解析；输入作为数据传入 JavaScriptCore，不执行输入代码。

## 新增工具

按[模块规范](module-specification.md)添加实现和测试，然后更新显式注册表：

```sh
python3 Scripts/update-registry.py
```

工程结构确需更新时再运行 `xcodegen generate`。JavaScript 资源应从 Swift Package 的源码扫描中排除，并包含在离线 bundle 中。

## 诊断与发布边界

worker 支持取消和超时终止，但不等于操作系统安全沙箱或严格的内存硬上限。网络、文件和解析器错误应保留可定位原因，日志不得包含正文或密钥。

Spotlight 需要有效开发者签名；索引可见和元数据存在不能替代执行验证。开发签名与 Developer ID 分发签名的应用共用 Bundle ID 时，Core Spotlight 可能拒绝开发版连接（日志包含 `higher-provenance (developer-id)`，界面表现为 `CSIndexErrorDomain -1003`）。使用上述 Debug/Release 独立标识避免身份冲突，无需删除 Release 或清理系统注册数据库。证书问题通过 Xcode 账户和签名设置处理，不使用私有权限或关闭系统保护。

临时构建、日志、截图、进程采样和测试报告保存在被忽略的 `build/` 或仓库外。知识文档只维护当前约束，不累计执行记录。
