# 模块开发规范

## 文件组织

一个工具对应 `Sources/DevKitCore/Tools/<id>/`。小工具可在 `<Name>Tool.swift` 中集中定义参数、字段和引擎；只有职责需要时才拆分。JavaScript 引擎使用同目录 `Engine.mjs`。专属界面或系统动作位于 `DevKit/Tools/<id>/`，不创建空目录。

核心测试位于 `Tests/DevKitCoreTests/`，会话与异步状态测试位于 `Tests/DevKitSessionTests/`。工具注册表由 `Scripts/update-registry.py` 生成。

## 实现契约

实现 `ToolModule`：

- `Options: ToolOptions` 定义可编码、可发送的强类型参数与默认值。
- `metadata` 提供稳定 ID、名称、分类、说明、示例、输入布局和联网标记。
- `fields` 定义字段类型、标签、取值方式和范围；`visibleFields` 与 `inputStyle` 可随操作变化。
- `example(for:)` 返回适合当前算法、语言或操作的示例。
- `execute(_:options:)` 接收不可变输入与参数，返回 `ToolOutput`，失败抛出 `ToolFailure`。

结果可以包含文本、条目、附件、受限 HTML、说明和 `ResultReport`。不要从 UI 文本反推结果语义，也不要将预览截断写回完整结果。

## 行为约束

参数显示范围与执行校验必须一致。空值、非法值、超限、取消和内部错误需区分；不要静默截断或统一 trim 原文。日期明确时区与历法，文本明确编码与换行口径，生成器明确随机或可重复种子语义。

引擎不读取 UI、剪贴板或全局选中工具。文件、网络等副作用必须由明确的调用路径承载；不能直接执行用户输入的代码或 Shell。

Base64 只处理 UTF-8 文本，标准与 URL Safe 显式选择。编码保留原文，解码支持完全省略末尾填充，非法字母表和非 UTF-8 结果应拒绝。所有入口共用核心算法。

## 接入检查

1. 确认工具 ID、分类、输入输出、默认参数、限制和与现有工具的区别。
2. 实现核心与行为测试，注册工具，复用已有会话和呈现组件。
3. 更新[工具目录](tool-catalog.md)与[实现范围](implementation-status.md)。
4. JavaScript 变更同步 bundle 和许可证；新增源文件按需同步工程结构。
5. 验证取消、输入修改、过期结果、复制、导出、错误恢复和资源边界。
6. 通过 Xcode Run 检查界面；Spotlight 适配另做系统端验证。

测试标准向量和可观察行为，不照抄实现细节。随机生成器验证约束，时间测试固定时区，网络测试使用受控服务。新依赖需说明版本、许可证、体积和适用范围。
