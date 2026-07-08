# GitHub 发布说明

这个目录已经是独立仓库形态，仓库名建议使用：

```text
cli-anything-dolphinscheduler
```

## 发布前检查

```bash
cd cli-anything-dolphinscheduler
./install.sh --dev --verify --install-skill --install-bin --force-installed-tests
```

如果你准备公开发布，先确认 `setup.py` 里的 `url` 已改成真实 GitHub 地址：

```python
url="https://github.com/<OWNER>/cli-anything-dolphinscheduler"
```

## 推送到已存在的 GitHub 仓库

先在 GitHub 创建空仓库，然后执行：

```bash
cd cli-anything-dolphinscheduler
./scripts/publish-github.sh git@github.com:<OWNER>/cli-anything-dolphinscheduler.git
```

也可以用 HTTPS remote：

```bash
./scripts/publish-github.sh https://github.com/<OWNER>/cli-anything-dolphinscheduler.git
```

脚本会执行：

- `git init`
- `git add .`
- 如果有变更则创建 commit
- 设置 `main` 分支
- 设置或更新 `origin`
- `git push -u origin main`

## 使用 GitHub CLI 创建仓库

如果本机已登录 `gh`，可以直接创建私有仓库：

```bash
cd cli-anything-dolphinscheduler
gh repo create cli-anything-dolphinscheduler --private --source=. --remote=origin --push
```

公开仓库把 `--private` 改成 `--public`。

## 发布后给 AI 的安装命令

把 `<OWNER>` 替换成真实 GitHub 用户或组织名：

```bash
REPO_URL="https://github.com/<OWNER>/cli-anything-dolphinscheduler.git"; INSTALL_DIR="${HOME}/.local/share/cli-anything-dolphinscheduler"; mkdir -p "$(dirname "$INSTALL_DIR")"; if [ -d "$INSTALL_DIR/.git" ]; then git -C "$INSTALL_DIR" pull --ff-only; else git clone "$REPO_URL" "$INSTALL_DIR"; fi && cd "$INSTALL_DIR" && chmod +x install.sh && ./install.sh --dev --verify --install-skill --install-bin --force-installed-tests
```

这条命令安装完成后，AI 下次会从 skills 目录发现：

```text
~/.codex/skills/cli-anything-dolphinscheduler/SKILL.md
~/.agents/skills/cli-anything-dolphinscheduler/SKILL.md
```

如果当前 shell 没有激活 `.venv`，让 AI 使用安装脚本最后打印的绝对 CLI 路径。
