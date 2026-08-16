# Codex Memory Vault

此目录是 Obsidian 打开的总 Vault，只负责容纳记忆分区；不要把 Vault 根目录注册为 Basic Memory Project。

推荐结构：

```text
<VAULT_PATH>/
├── global/                 # 一个独立的全局 Basic Memory Project
│   ├── conversations/
│   ├── inbox/
│   ├── profile/
│   ├── knowledge/
│   ├── experience/
│   └── decisions/
└── projects/
    └── <PROJECT_SLUG>/     # 一个独立的项目 Basic Memory Project
        ├── checkpoints/
        ├── remember/
        ├── decisions/
        └── experience/
```

## 边界规则

- `global/` 与每个 `projects/<PROJECT_SLUG>/` 分别注册，路径不得重叠。
- 一个 Basic Memory Project 不能包含另一个已注册 Project。
- 普通对话只写全局 Project；项目任务写自己的项目 Project。
- 项目可以把全局 Project 配成只读辅助来源，但项目之间默认不可互读。
- 项目经验提升到全局前，应先总结、脱敏并由用户确认。
- 真实 Vault 应位于本框架 Git 仓库之外。
