# DevKit 项目上下文

这里保存供编码代理按需读取的项目知识。根目录 [AGENTS.md](../../AGENTS.md) 是共用约定，Claude Code 通过 [.claude/CLAUDE.md](../../.claude/CLAUDE.md) 导入它。只阅读当前任务相关主题，不将所有文档一次性载入。

| 任务 | 参考 |
| --- | --- |
| 理解产品目标 | [产品要求](product-requirements.md) |
| 查找工具与能力边界 | [工具目录](tool-catalog.md)、[实现范围](implementation-status.md) |
| 修改模块、会话、执行服务 | [架构](architecture.md)、[模块规范](module-specification.md) |
| 构建、依赖、签名与发布 | [开发维护](development.md) |
| 页面、控件、编辑器和多窗口 | [交互约束](interaction-design.md)、[视觉约束](visual-design.md)、[行为参考](user-guide.md) |
| 文件、网络、剪贴板与敏感数据 | [数据与权限](data-and-permissions.md) |
| 系统动作与命令 | [Spotlight](spotlight-design.md) |
| CLI、参数发现与 AI Skill | [架构](architecture.md)、[CLI 使用教程](../../docs/cli-and-ai.md) |
| 验证改动与性能目标 | [测试要求](acceptance-plan.md) |

文档描述当前状态、约束和未解决事项。修改时直接更新对应主题，不追加日期标题、工作日记、验收流水、提交清单或本机日志。历史由 Git 保存；临时证据留在已忽略目录或仓库外。

根目录 [README](../../README.md) 面向项目访问者；[docs](../../docs/README.md) 用于面向用户的网页教程。开发内部资料集中维护在本目录，不复制到两个代理目录。
