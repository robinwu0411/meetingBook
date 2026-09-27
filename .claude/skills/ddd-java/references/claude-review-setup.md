# Claude Code 安装与约束

将 ddd-java 放入 ~/.claude/skills/ddd-java，或项目 .claude/skills/ddd-java。现有项目执行：

```bash
python3 ~/.claude/skills/ddd-java/scripts/install-review-controls.py /你的项目路径
```

新项目创建脚本自动执行安装。安装器把 review-workflow.md 复制为项目 `.claude/rules/ddd-review.md`，并在 `.claude/settings.local.json` 的 permissions.ask 中合并 `Bash(git *)`。规则已有不同内容时停止，不覆盖；配置已有其他字段保留。项目 CLAUDE.md 保留。

Git ask 会让常见 git 命令（包括 diff/status/commit）请求确认，覆盖 git -C 等以 git 开头的写法。比只拦 git commit 更宽，也会增加只读操作提示。选择仅本次允许，避免授予长期放行。进入项目后用 /permissions 检查实际加载设置；不要使用跳过权限检查模式。配置文件不能取消启动参数或其他管理策略。

自然语言规则不是确定性状态机。Skill 仅在加载时起作用，所以另外安装不带 paths 限制的项目 rules，让分步验收要求随项目加载。Superpowers 的计划也必须包含每个待 review 停点，不允许连续执行跨过停点。

Bash 模式匹配只检查命令形式，不会分析脚本内部的 git 调用，也不覆盖其他工具提交。不能把此配置称为绝对防绕过的提交锁。若要求更严格，使用默认交互权限模式，对 Bash 及写入工具逐次审批；或由用户在 IntelliJ 手动 commit，并禁止 Claude 提交。真正自动执行的阶段门禁需要外部管理的审批状态和 PreToolUse hook 校验允许文件范围，不能让模型自己写一个 approved=true 作为凭证。本包没有实现这种外部门禁。

开新会话时可以说：“使用 ddd-java，先按 user story 列 Task。同一 Task 内一次只写一个 Controller 或一个小步骤，完成列出修改文件并停下，等我 accept；测试通过后单独问我是否 commit。”

settings.local.json 是本地权限配置，不等于 review 状态机；在对话中 accept 也不会自动解除工具权限确认。

官方文档：
- https://code.claude.com/docs/en/memory
- https://code.claude.com/docs/en/permissions
- https://code.claude.com/docs/en/hooks
