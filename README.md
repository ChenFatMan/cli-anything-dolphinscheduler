# cli-anything-dolphinscheduler

CLI-Anything harness for Apache DolphinScheduler. It lets Codex and other AI
agents call a running DolphinScheduler API server from the command line with
machine-readable `--json` output.

This is not a scheduler reimplementation. Every operation goes through the real
DolphinScheduler REST API, the same backend used by the web UI.

## Codex Auto-Install

Give this single command to Codex or another AI agent:

```bash
REPO_URL="git@github.com:ChenFatMan/cli-anything-dolphinscheduler.git"; INSTALL_DIR="${HOME}/.local/share/cli-anything-dolphinscheduler"; mkdir -p "$(dirname "$INSTALL_DIR")"; if [ -d "$INSTALL_DIR/.git" ]; then git -C "$INSTALL_DIR" pull --ff-only; else git clone "$REPO_URL" "$INSTALL_DIR"; fi && cd "$INSTALL_DIR" && chmod +x install.sh && ./install.sh --dev --verify --install-skill --install-bin --force-installed-tests
```

It installs:

- executable package in a local `.venv`
- stable launcher: `~/.local/bin/cli-anything-dolphinscheduler`
- Codex skill: `~/.codex/skills/cli-anything-dolphinscheduler/SKILL.md`
- generic agent skill: `~/.agents/skills/cli-anything-dolphinscheduler/SKILL.md`

After that, a new Codex session can discover the skill and directly call
`cli-anything-dolphinscheduler`.

## Connect to DolphinScheduler

The API server must be reachable. Default local server:

```bash
export DS_URL=http://localhost:12345/dolphinscheduler
export DS_TOKEN=<access-token>
```

Username/password also works:

```bash
export DS_URL=http://localhost:12345/dolphinscheduler
export DS_USER=admin
export DS_PASSWORD=dolphinscheduler123
```

Verify:

```bash
cli-anything-dolphinscheduler login
cli-anything-dolphinscheduler --json project list
```

## What Codex Can Do

| Area | Commands |
|------|----------|
| Projects | `project create/list/use/current/delete` |
| Resource Center | `resource base-dir/tree/list/mkdir/create-file/upload/view/update-content/replace/rename/download/delete` |
| Task JSON | `task build-shell/build-python/build-sql/build-http/build-generic` |
| Workflows | `workflow create-shell/list/release/delete` |
| Runs | `run start/control` |
| Instances | `instance list/get/tasks/task-list/force-task-success/stop-task/delete` |
| Schedules | `schedule create/list` |
| Tokens | `token create/list` |

High-level workflow creation currently has a `workflow create-shell` shortcut.
For non-shell tasks, build `taskDefinitionJson` with `task build-*`; use
`task build-generic` for plugin types such as `SPARK`, `FLINK`, `DATAX`, `K8S`,
and `SUB_PROCESS` by passing the exact DolphinScheduler `taskParams` JSON.

## Common AI Flow

```bash
cli-anything-dolphinscheduler --json project create "AgentProject"
cli-anything-dolphinscheduler project use "AgentProject"

BASE_DIR="$(cli-anything-dolphinscheduler --json resource base-dir | python3 -c 'import json,sys; print(json.load(sys.stdin)["data"]["fullName"])')"

cli-anything-dolphinscheduler --json resource create-file \
  --name hello.py \
  --current-dir "$BASE_DIR" \
  --content "print('hello from DolphinScheduler')"

cli-anything-dolphinscheduler workflow create-shell \
  --name "agent_smoke" \
  --task "hello:echo hello" \
  --online

cli-anything-dolphinscheduler --json run start "agent_smoke"
cli-anything-dolphinscheduler --json instance task-list --state FAILURE
```

## Manual Install

```bash
git clone git@github.com:ChenFatMan/cli-anything-dolphinscheduler.git
cd cli-anything-dolphinscheduler
chmod +x install.sh
./install.sh --dev --verify --install-skill --install-bin
```

## Documentation

- [中文 Agent 使用手册](AGENT_USAGE.zh-CN.md)
- [中文安装与使用说明](INSTALL.zh-CN.md)
- [English install guide](INSTALL.md)
- [Full command reference](cli_anything/dolphinscheduler/README.md)
- [AI skill](skills/cli-anything-dolphinscheduler/SKILL.md)

## Development

```bash
source .venv/bin/activate
python3 -m pytest cli_anything/dolphinscheduler/tests/test_core.py -v
CLI_ANYTHING_FORCE_INSTALLED=1 python3 -m pytest cli_anything/dolphinscheduler/tests/test_subprocess.py -v
```

## License

MIT
