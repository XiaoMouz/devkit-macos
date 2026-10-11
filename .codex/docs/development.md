# 开发与维护

## Xcode 工作流

遵守根目录 [AGENTS.md](../../AGENTS.md)。打开 `DevKit.xcodeproj`，选择 `DevKit / My Mac`，通过 `⌘R` 运行 Debug；交互验收只使用 Xcode 当前启动的这份应用。

归档使用 `Product → Archive`，在 Organizer 中完成分发签名、导出或上传。只有用户明确要求实际发布时才上传。不要添加独立构建、打包、重签名、安装、启动或注册清理脚本。

签名在 Signing & Capabilities 和 `Config/Signing.xcconfig` 中配置；机器私有覆盖放在被忽略的 `Config/Signing.local.xcconfig`。不得覆盖用户团队和证书。若本地包被另一 Xcode 窗口占用，关闭单独打开的 Swift Package，再打开应用工程。

`project.yml` 是工程结构来源，仅在结构变化时使用 XcodeGen 同步；生成前检查工作区，避免覆盖未提交工程修改。应用图标源为 `DevKit/Resources/AppIcon.icon`，使用 Icon Composer 编辑，由 Xcode 编译。

## 核心与会话测试

```sh
swift test
zsh Scripts/test-editor.sh
zsh Scripts/test-appearance.sh
```

编辑器回归编译实际组件，使用隐藏测试窗口和独立粘贴板；它不是另一份 DevKit 验收应用。只修改文档时检查链接和内容即可，不重建应用。

编辑器性能变更可运行 `zsh Scripts/test-editor.sh --benchmark`，测量 100,000 字节中英混合文本的输入与原地刷新耗时。它使用同一隐藏组件测试进程，报告中位数及最大值，不将依赖机器负载的耗时设为测试通过阈值。交互验收仍使用 Xcode 启动的应用。

检查 worker、CLI 和 Spotlight 元数据时，显式传入从 Xcode 获取的应用路径：

```sh
python3 Scripts/integration-tests.py "/path/from/Xcode/DevKit.app"
python3 Scripts/check-spotlight-metadata.py "/path/from/Xcode/DevKit.app"
```

CLI 集成覆盖包内执行、软链接调用、解析器资源、文件和 JSON 输入、附件、错误与超时、受控本地网络。`swift test` 另覆盖参数校验、注册表默认值、安装冲突与隔离临时目录中的 Shell PATH 配置，不改写测试机器的真实启动文件。修改配套 Skill 时同步 `Sources/DevKitCore/Resources/Skills/devkit` 和面向用户的 [CLI 教程](../../docs/cli-and-ai.md)。

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

Spotlight 需要有效开发者签名；索引可见和元数据存在不能替代执行验证。证书问题通过 Xcode 账户和签名设置处理，不使用私有权限或关闭系统保护。

临时构建、日志、截图、进程采样和测试报告保存在被忽略的 `build/` 或仓库外。知识文档只维护当前约束，不累计执行记录。
