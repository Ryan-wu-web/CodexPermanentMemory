# 安全与隐私

这个仓库只用于保存 Codex 长期记忆的框架、模板和文档。真实记忆应始终保存在仓库之外的本地 Obsidian Vault 中。

## 绝对不要提交

- 对话内容、检查点、个人偏好、项目决策或知识笔记；
- 真实的 `.codex/basic-memory.json`、Basic Memory 数据库与索引；
- Obsidian 工作区状态、插件私有数据、Hook inbox、日志或备份；
- 用户名、真实绝对路径、内部项目名、邮箱、令牌、密码、私钥或证书。

配置示例必须使用 `<VAULT_PATH>`、`<GLOBAL_MEMORY_PROJECT>`、`<PROJECT_MEMORY_PROJECT>`、`<PROJECT_ROOT>` 等占位符。

## 私有仓库不是加密保险箱

GitHub private 只限制访问范围，不等于端到端加密，也不能消除误授权、账号失陷、日志留存或 Git 历史泄漏风险。真实记忆和凭据不应因为仓库是 private 就被提交。

## 提交前检查

在仓库根目录执行：

```powershell
pwsh -NoProfile -File scripts/Test-CodexMemoryFramework.ps1
```

脚本会检查必需文件、JSON 模板、Markdown 围栏和常见敏感信息。它只能降低误提交概率，不能代替人工审阅：提交前仍应检查 `git status` 和暂存差异。

## 如果敏感信息已经进入 Git

1. 立即停止推送和分享仓库。
2. 若包含令牌、密码或密钥，先在对应服务中撤销并轮换；仅从文件中删除并不安全。
3. 使用经过审阅的历史重写方案清除全部相关提交、分支和标签。
4. 重新扫描完整历史，并通知所有已获得旧副本的协作者。

不要在公开 Issue 中粘贴敏感内容。安全问题请通过仓库所有者提供的私密联系方式报告；在专用安全渠道建立前，可使用 GitHub 的私密漏洞报告功能（如果仓库已启用）。
