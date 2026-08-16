# Codex Permanent Memory

一个面向 Codex + Basic Memory + Obsidian 的本地长期记忆参考框架。

> 本仓库只保存框架、模板、脚本和文档，不保存任何使用者的真实记忆。真实 Markdown、索引、数据库、私有配置和备份必须位于仓库之外。

## 它解决什么问题

- 长任务发生上下文压缩后，可以用结构化检查点继续工作；
- 普通对话和通用知识进入全局记忆；
- 每个代码或工作项目拥有独立记忆，默认互不检索；
- Obsidian 统一浏览 Markdown，Basic Memory 按 Project 提供本地检索和关系；
- 记忆保持人可读、可编辑和可迁移，而不是只存在于聊天窗口。

## 快速开始

### 1. 克隆框架

```powershell
git clone https://github.com/Ryan-wu-web/CodexPermanentMemory.git
Set-Location CodexPermanentMemory
```

### 2. 在仓库外创建记忆目录

```powershell
pwsh -NoProfile -File scripts/New-CodexMemoryLayout.ps1 `
  -VaultPath '<VAULT_PATH>' `
  -ProjectSlug 'example-project'
```

`<VAULT_PATH>` 必须是你自己的仓库外目录，不能是磁盘根目录或用户主目录。脚本不会安装依赖、修改 Codex 配置或注册 Basic Memory Project。

### 3. 安装并配置外部依赖

按[部署指南](docs/deployment-guide.md)安装 Basic Memory Codex 插件，分别把：

- `<VAULT_PATH>/global` 注册为全局 Project；
- `<VAULT_PATH>/projects/example-project` 注册为独立项目 Project。

不要注册 `<VAULT_PATH>` 根目录，也不要让 Project 路径互相包含。

### 4. 复制配置模板

- 用户级模板：`templates/user/basic-memory.example.json`
- 项目级模板：`templates/project/basic-memory.example.json`

复制到目标位置后替换 `<PLACEHOLDER>`。修改后的真实配置不要提交回本仓库。

### 5. 运行检查

```powershell
pwsh -NoProfile -File tests/Test-NewCodexMemoryLayout.ps1
pwsh -NoProfile -File scripts/Test-CodexMemoryFramework.ps1
```

## 目录

```text
.
├── docs/
│   ├── architecture.md
│   ├── deployment-guide.md
│   └── user-guide.md
├── scripts/
│   ├── New-CodexMemoryLayout.ps1
│   └── Test-CodexMemoryFramework.ps1
├── templates/
│   ├── project/
│   ├── user/
│   └── vault/
├── tests/
├── SECURITY.md
└── README.md
```

## 文档入口

- [核心架构](docs/architecture.md)：组件职责、作用域隔离、保存和恢复链路。
- [部署指南](docs/deployment-guide.md)：从空环境到隔离验收。
- [日常使用手册](docs/user-guide.md)：何时保存、保存到哪里、如何恢复。
- [安全与隐私](SECURITY.md)：禁止入库的数据和泄漏处理。

## 隐私模型

这个框架依赖三层边界：

1. 真实 Vault 与 Git 框架仓库物理分离；
2. Basic Memory 以独立 Project 隔离全局和各项目检索；
3. 提交前静态扫描与人工 Git 审阅。

私有 GitHub 仓库不等于加密存储。不要提交真实记忆或凭据。

## 依赖与许可证边界

- [Basic Memory](https://github.com/basicmachines-co/basic-memory) 是外部项目；本参考版本以 `v0.22.1` 为基线。其核心仓库许可证以官方仓库当前声明为准（该版本为 GNU AGPL-3.0）；本仓库不复制其源码。
- Codex 属于 OpenAI；请参阅 [Codex 官方文档](https://developers.openai.com/codex/)。本仓库不代表 OpenAI 或 Basic Machines。
- 本仓库自身采用 [MIT License](LICENSE)，允许使用、修改、分发和商业使用，但必须保留版权与许可证声明。

## 当前状态

这是 Windows / PowerShell 优先的参考实现：目录脚手架和静态验证可本地测试，安装与 Project 映射仍需要使用者确认。欢迎通过 GitHub Issue 提交文档纠错、跨平台脚本和隔离测试改进；请勿在 Issue 中附带真实记忆、绝对路径或凭据。

## 开发与贡献

修改后运行：

```powershell
pwsh -NoProfile -File tests/Test-NewCodexMemoryLayout.ps1
pwsh -NoProfile -File scripts/Test-CodexMemoryFramework.ps1
git status --short
```

提交前同时人工检查暂存差异。静态扫描用于降低风险，不能证明仓库绝对不含敏感信息。
