# LSJSONModel Claude Code 配置

> LSJSONModel 项目的 Claude Code 配置文件
>
> 提供 Agents、Commands、Rules、Skills 等配置

---

## 目录结构

```
.claude/
├── agents/              # 子代理配置
│   ├── planner.md       # 实现规划
│   ├── code-reviewer.md  # 代码审查
│   └── architect.md      # 架构设计
├── commands/            # 斜杠命令
│   ├── plan.md          # /plan - 规划实现
│   ├── test.md          # /test - 运行测试
│   └── build.md         # /build - 构建项目
├── rules/               # 规则（必须遵循）
│   ├── naming.md        # 命名规范
│   ├── coding-style.md   # 编码风格
│   └── json-patterns.md  # JSON 模式
└── skills/              # 技能/领域知识
    ├── swift-patterns/   # Swift 模式
    └── codable-patterns/ # Codable 模式
```

---

## 安装

将此目录复制到项目根目录：

```bash
cp -r .claude ~/.claude/
```

或直接复制到用户配置：

```bash
cp agents/* ~/.claude/agents/
cp commands/* ~/.claude/commands/
cp rules/* ~/.claude/rules/
cp -r skills/* ~/.claude/skills/
```
