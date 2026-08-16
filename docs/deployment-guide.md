# 部署指南（Windows / PowerShell）

本指南部署的是框架。真实记忆会写入你自己指定的仓库外 Obsidian Vault，不会写进本 Git 仓库。

## 1. 前置条件

- Windows 10/11；
- PowerShell 7（命令为 `pwsh`）；
- Git；
- Codex Desktop 或支持插件的 Codex 环境；
- [Obsidian](https://obsidian.md/)（推荐，用于人工浏览 Markdown）；
- [uv](https://docs.astral.sh/uv/)；Basic Memory Codex Hook 使用它运行固定版本环境。

本参考实现以 [Basic Memory v0.22.1](https://github.com/basicmachines-co/basic-memory/releases/tag/v0.22.1) 为基线。Codex 的最新安装与插件说明以 [OpenAI Codex 官方文档](https://developers.openai.com/codex/) 为准。

## 2. 获取框架

```powershell
git clone https://github.com/Ryan-wu-web/CodexPermanentMemory.git
Set-Location CodexPermanentMemory
```

仓库自身不应该包含 `memory-data/`、`vault-data/` 或真实 `.codex/basic-memory.json`。

## 3. 在仓库外创建 Vault 布局

先选择一个不在本框架 Git 仓库中的目录，替换 `<VAULT_PATH>`：

```powershell
pwsh -NoProfile -File scripts/New-CodexMemoryLayout.ps1 `
  -VaultPath '<VAULT_PATH>' `
  -ProjectSlug 'example-project'
```

脚本只创建目录和根 README：

```text
<VAULT_PATH>/
├── global/
│   ├── conversations/
│   ├── inbox/
│   ├── profile/
│   ├── knowledge/
│   ├── experience/
│   └── decisions/
└── projects/
    └── example-project/
        ├── checkpoints/
        ├── remember/
        ├── decisions/
        └── experience/
```

脚本是幂等的，不覆盖已有 README，也不会安装软件、注册 Basic Memory Project 或修改 Codex 配置。它会拒绝磁盘根目录和用户主目录。

在 Obsidian 中选择“打开本地文件夹作为仓库”，打开 `<VAULT_PATH>`。

## 4. 安装 Basic Memory Codex 插件

Basic Memory 插件的官方 `v0.22.1` 说明要求先安装 `uv`，再从 Basic Memory 仓库根目录添加 marketplace。以下命令会克隆外部项目并安装用户级 Codex 插件；执行前请阅读其官方仓库和许可证：

```powershell
git clone --branch v0.22.1 https://github.com/basicmachines-co/basic-memory.git
Set-Location basic-memory
codex plugin marketplace add (git rev-parse --show-toplevel)
codex plugin add codex@basic-memory
```

如果从 Codex 图形界面添加 marketplace，Sparse paths 保持为空。安装或升级插件属于用户级变更，应由使用者明确执行。

安装后新建一个 Codex 任务，让 Skills、MCP 配置和 Hooks 被重新加载。打开 Codex 的 `/hooks` 页面，阅读并信任 Basic Memory Hook 定义后再启用。

## 5. 注册互不重叠的 Basic Memory Projects

使用 Basic Memory 的项目管理界面，或在 Codex 中运行 `$bm-setup`，创建并确认以下映射：

| 用途 | Project 名称示例 | 本地路径 |
| --- | --- | --- |
| 全局记忆 | `<GLOBAL_MEMORY_PROJECT>` | `<VAULT_PATH>/global` |
| 项目记忆 | `<PROJECT_MEMORY_PROJECT>` | `<VAULT_PATH>/projects/example-project` |

必须遵守：

- 不注册 `<VAULT_PATH>` 根目录；
- 两个 Project 的路径不能相同、重叠或互相包含；
- 每增加一个真实项目，新增一个独立 Project；
- 创建或选择写入目标时，必须由用户确认，不能仅根据目录名猜测。

`$bm-setup` 还会为目标 Project 写入 Codex 会话、决定和任务的 schema。目标与预期不一致时不要继续。

## 6. 配置用户级全局记忆

复制模板到用户级 Codex 配置目录：

```powershell
New-Item -ItemType Directory -Path (Join-Path $HOME '.codex') -Force
Copy-Item templates/user/basic-memory.example.json `
  (Join-Path $HOME '.codex/basic-memory.json')
```

打开目标文件，把 `<GLOBAL_MEMORY_PROJECT>` 替换为你刚确认的全局 Project 名称。不要把修改后的真实配置复制回本仓库。

此模板会把：

- 普通会话检查点写到 `conversations/`；
- 轻量事实写到 `inbox/`；
- 默认回忆窗口设为 30 天；
- 上下文压缩检查点和本地生命周期事件捕获设为开启。

## 7. 配置项目级记忆

在真实工作项目根目录执行，而不是在本框架仓库中执行：

```powershell
Set-Location '<PROJECT_ROOT>'
New-Item -ItemType Directory -Path '.codex' -Force
Copy-Item '<FRAMEWORK_ROOT>/templates/project/basic-memory.example.json' `
  '.codex/basic-memory.json'
```

替换：

- `<PROJECT_MEMORY_PROJECT>`：该项目独占的 Basic Memory Project；
- `<GLOBAL_MEMORY_PROJECT>`：全局 Project，作为辅助读取来源；
- `<REPOSITORY_IDENTIFIER>`：稳定仓库标识，GitHub 项目通常使用 `owner/repository`。

项目模板使用 `coding` profile。它要求当前目录是已有 HEAD 的 Git 仓库；如果项目还没有首个 commit，先把 `sessionProfile` 改为 `general` 并移除 `repository`，有首个 commit 后再切回 `coding`。

项目级键会覆盖用户级同名键，因此项目任务写入自己的 Project，而普通对话仍使用全局 Project。

## 8. MCP 审批模式（可选）

默认保留 Codex 的正常审批行为即可。若你希望预批准 Basic Memory MCP 中符合条件的工具，按插件官方说明在 `~/.codex/config.toml` 中配置该服务器范围的审批模式：

```toml
[plugins."codex@basic-memory".mcp_servers.basic-memory]
default_tools_approval_mode = "approve"
```

这不会关闭 Codex 的全局审批，也不会授予 Basic Memory 新目录权限；标记为破坏性的写、改、删工具仍可能要求批准。修改用户级 Codex 配置后需新建任务。不要为减少提示而把全局审批策略改成 `never`。

## 9. 验收

### 框架自检

```powershell
pwsh -NoProfile -File tests/Test-NewCodexMemoryLayout.ps1
pwsh -NoProfile -File scripts/Test-CodexMemoryFramework.ps1
```

预期看到：

```text
LAYOUT_TEST=PASS
FRAMEWORK_TEST=PASS
```

### Basic Memory 状态

新建 Codex 任务并运行 `$bm-status`，确认：

- `primaryProject` 与当前作用域相符；
- 项目任务的 `secondaryProjects` 包含全局 Project；
- `general`/`coding` profile 与当前配置相符；
- Hook 已安装且已审阅；
- Basic Memory MCP 可列出正确的 Projects。

### 隔离测试

1. 在普通任务中，用 `$bm-remember` 保存一个无敏感信息的全局测试事实。
2. 在真实项目任务中，保存另一个项目测试事实。
3. 从全局 Project 搜索，只应找到全局事实。
4. 从项目 Project 搜索，应找到项目事实；若配置了全局辅助读取，可另外读到全局事实。
5. 从另一个项目搜索，不应找到该项目事实。
6. 删除测试笔记前再次确认目标 Project 和标识。

## 10. 常见问题

### 新任务里看不到 Skill 或 Hook

插件安装或配置变更只会在新任务加载。关闭旧任务后新建一个；同时检查 `/hooks` 信任状态。

### 项目记忆写进了全局区

检查当前工作目录是否在 `<PROJECT_ROOT>` 内，以及最近的 `.codex/basic-memory.json` 是否存在并可解析。项目文件按键覆盖用户级文件；缺失时会回退到全局配置。

### 搜索结果混入其他项目

检查是否误把 Vault 根注册为 Project，或 Project 路径是否互相包含。修正映射前先备份，不要在有多个活动任务监视旧路径时迁移目录。

### `coding` 检查点失败

确认仓库有首个 commit、可以解析当前分支和 SHA，并且 `repository` 是已确认的稳定标识。新项目在此之前使用 `general`。

### 隐私扫描通过就一定安全吗

不是。静态扫描只覆盖常见模式；提交前仍需人工检查 Git 候选文件和暂存差异。
