# cli-anything-dolphinscheduler 中文安装与使用说明

可以直接安装给 AI，让后续 AI 自己调用。这个仓库的安装分两层：

- `--install-bin`：安装稳定 launcher 到 `~/.local/bin/cli-anything-dolphinscheduler`。
- `--install-skill`：把 skill 安装到 `~/.codex/skills` 和 `~/.agents/skills`，让新 AI 会话能发现如何使用这个 CLI。

安装完成后，新的 AI 会话可以通过 `cli-anything-dolphinscheduler` 这个命令调用真实 DolphinScheduler API。当前会话若还没重新加载 skill，也可以直接调用 `~/.local/bin/cli-anything-dolphinscheduler`。

## 给 AI 自动安装的一条命令

GitHub 仓库创建后，把 `<OWNER>` 换成真实 GitHub 用户或组织名：

```bash
REPO_URL="https://github.com/<OWNER>/cli-anything-dolphinscheduler.git"; INSTALL_DIR="${HOME}/.local/share/cli-anything-dolphinscheduler"; mkdir -p "$(dirname "$INSTALL_DIR")"; if [ -d "$INSTALL_DIR/.git" ]; then git -C "$INSTALL_DIR" pull --ff-only; else git clone "$REPO_URL" "$INSTALL_DIR"; fi && cd "$INSTALL_DIR" && chmod +x install.sh && ./install.sh --dev --verify --install-skill --install-bin --force-installed-tests
```

同一条命令保存在：

```text
AI_INSTALL_COMMAND.txt
```

如果已经在本仓库根目录：

```bash
chmod +x install.sh
./install.sh --dev --verify --force-installed-tests --install-skill --install-bin
```

这会创建 `.venv`，安装 CLI，安装 AI skill，安装 launcher，并跑基础验证和 subprocess 测试。

## 手动安装

推荐方式：

```bash
cd cli-anything-dolphinscheduler
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -U pip
python3 -m pip install -e '.[dev]'
cli-anything-dolphinscheduler --version
```

或者使用安装脚本：

```bash
./install.sh --dev --verify --install-skill --install-bin
```

常用参数：

| 参数 | 作用 |
|------|------|
| `--dev` | 安装测试依赖 |
| `--verify` | 安装后验证 CLI |
| `--force-installed-tests` | 强制用已安装命令跑 subprocess 测试 |
| `--install-skill` | 安装 AI skill 到默认 skills 目录 |
| `--skill-dir DIR` | 指定额外 skills 根目录 |
| `--install-bin` | 安装 launcher 到 `~/.local/bin` |
| `--bin-dir DIR` | 指定 launcher 安装目录 |
| `--venv DIR` | 指定虚拟环境目录 |
| `--system` | 使用当前 Python 环境，不创建 `.venv` |
| `--user` | 配合 `--system` 做用户级安装 |

## 配置 DolphinScheduler

CLI 需要能访问真实 DolphinScheduler API Server。默认地址：

```text
http://localhost:12345/dolphinscheduler
```

推荐使用 token：

```bash
export DS_URL=http://localhost:12345/dolphinscheduler
export DS_TOKEN=<access-token>
```

也可以使用用户名和密码：

```bash
export DS_URL=http://localhost:12345/dolphinscheduler
export DS_USER=admin
export DS_PASSWORD=dolphinscheduler123
```

持久化配置：

```bash
cli-anything-dolphinscheduler \
  --url http://localhost:12345/dolphinscheduler \
  --user admin \
  --password dolphinscheduler123 \
  config set
```

配置优先级：CLI 参数 > 环境变量 > 配置文件 > 默认值。

## 基础使用

AI 调用时建议始终加 `--json`。

```bash
cli-anything-dolphinscheduler --json project list
cli-anything-dolphinscheduler project create "Analytics"
cli-anything-dolphinscheduler project use "Analytics"
cli-anything-dolphinscheduler --json workflow list
```

创建并运行一个简单 SHELL 工作流：

```bash
cli-anything-dolphinscheduler workflow create-shell \
  --name "agent_smoke" \
  --task "hello:echo hello" \
  --online

cli-anything-dolphinscheduler --json run start "agent_smoke"
```

查看实例和任务：

```bash
cli-anything-dolphinscheduler --json instance list --page-size 10
cli-anything-dolphinscheduler --json instance tasks <workflow-instance-id>
cli-anything-dolphinscheduler --json instance task-list --workflow-instance-id <workflow-instance-id>
```

## Task 构造不是只有 SHELL

`workflow create-shell` 只是高频快捷入口，不代表只能创建 SHELL。构造 `taskDefinitionJson` 用 `task` 分组：

```bash
cli-anything-dolphinscheduler task --help
```

已提供：

| 命令 | 任务类型 |
|------|----------|
| `task build-shell` | `SHELL` |
| `task build-python` | `PYTHON` |
| `task build-sql` | `SQL` |
| `task build-http` | `HTTP` |
| `task build-generic` | 任意 DolphinScheduler task plugin |

示例：

```bash
cli-anything-dolphinscheduler --json task build-python \
  --name py_task \
  --script "print('ok')" \
  --code 1001

cli-anything-dolphinscheduler --json task build-sql \
  --name query_task \
  --sql "select 1" \
  --datasource 10 \
  --code 1002

cli-anything-dolphinscheduler --json task build-http \
  --name health_check \
  --url "https://example.com/health" \
  --method GET \
  --code 1003

cli-anything-dolphinscheduler --json task build-generic \
  --name spark_job \
  --task-type SPARK \
  --params-json '{"mainClass":"org.example.Job"}' \
  --code 1004
```

`build-generic` 覆盖 SPARK、FLINK、DATAX、K8S、SUB_PROCESS 等未提供 typed builder 的插件任务。它不会猜参数，`--params-json` 必须是 DolphinScheduler server/plugin 真实期望的 `taskParams` JSON。

`--code` 规则：

- 传 `--code`：离线构造 JSON，不访问 server 分配 task code。
- 不传 `--code`：从当前项目或 `--project-code` 调用 DolphinScheduler API 分配真实 task code。

## AI 使用规则

- 新会话先让 AI 读取 skill：`~/.codex/skills/cli-anything-dolphinscheduler/SKILL.md`。
- 机器解析场景始终用 `--json`。
- 如果 `cli-anything-dolphinscheduler` 不在 `PATH`，用 `~/.local/bin/cli-anything-dolphinscheduler`。
- 非零退出码代表失败；错误 JSON 通常在 stderr。
- 先用 `project use <name-or-code>` 选择项目，或每次显式传 `--project-code`。
- `run start` 前工作流必须 ONLINE。
- 排查任务失败优先用 `instance task-list` 和 `instance tasks`。

## 测试

```bash
./install.sh --help
./install.sh --verify
source .venv/bin/activate
python3 -m pytest cli_anything/dolphinscheduler/tests/test_core.py -v
CLI_ANYTHING_FORCE_INSTALLED=1 python3 -m pytest cli_anything/dolphinscheduler/tests/test_subprocess.py -v
```

真实 E2E 测试需要正在运行的 DolphinScheduler API Server：

```bash
python3 -m pytest -m e2e cli_anything/dolphinscheduler/tests/test_full_e2e.py -v
```

## 推送到 GitHub

见 [GITHUB.md](GITHUB.md) 或 [PUBLISH.zh-CN.md](PUBLISH.zh-CN.md)。需要一个真实的 GitHub remote URL，例如：

```text
git@github.com:<owner>/cli-anything-dolphinscheduler.git
```

## 卸载

```bash
python3 -m pip uninstall cli-anything-dolphinscheduler
rm -f ~/.local/bin/cli-anything-dolphinscheduler
rm -rf ~/.codex/skills/cli-anything-dolphinscheduler
rm -rf ~/.agents/skills/cli-anything-dolphinscheduler
```
