# cli-anything-dolphinscheduler

CLI-Anything harness for Apache DolphinScheduler. It gives AI agents and scripts
a structured command-line interface to a running DolphinScheduler API server.

This CLI does not reimplement scheduling. It calls the real DolphinScheduler
REST API, the same backend used by the web UI.

## AI Auto-Install

After publishing this repository to GitHub, replace `<OWNER>` and give this
command to an AI agent:

```bash
REPO_URL="https://github.com/<OWNER>/cli-anything-dolphinscheduler.git"; INSTALL_DIR="${HOME}/.local/share/cli-anything-dolphinscheduler"; mkdir -p "$(dirname "$INSTALL_DIR")"; if [ -d "$INSTALL_DIR/.git" ]; then git -C "$INSTALL_DIR" pull --ff-only; else git clone "$REPO_URL" "$INSTALL_DIR"; fi && cd "$INSTALL_DIR" && chmod +x install.sh && ./install.sh --dev --verify --install-skill --install-bin --force-installed-tests
```

The command installs:

- the executable `cli-anything-dolphinscheduler`
- a stable launcher at `~/.local/bin/cli-anything-dolphinscheduler`
- a local `.venv` under the cloned repository
- the AI skill file under `~/.codex/skills` and `~/.agents/skills`

Once installed, an agent can discover the skill and call the CLI directly.

## Local Install

```bash
git clone https://github.com/<OWNER>/cli-anything-dolphinscheduler.git
cd cli-anything-dolphinscheduler
chmod +x install.sh
./install.sh --dev --verify --install-skill --install-bin
```

## Configure DolphinScheduler

Token auth:

```bash
export DS_URL=http://localhost:12345/dolphinscheduler
export DS_TOKEN=<access-token>
```

Username/password:

```bash
export DS_URL=http://localhost:12345/dolphinscheduler
export DS_USER=admin
export DS_PASSWORD=dolphinscheduler123
```

## Basic Usage

```bash
cli-anything-dolphinscheduler --json project list
cli-anything-dolphinscheduler project use <project-name-or-code>
cli-anything-dolphinscheduler --json workflow list
```

Create and run a simple workflow:

```bash
cli-anything-dolphinscheduler workflow create-shell \
  --name "agent_smoke" \
  --task "hello:echo hello" \
  --online

cli-anything-dolphinscheduler --json run start "agent_smoke"
```

Build task JSON for non-shell task types:

```bash
cli-anything-dolphinscheduler --json task build-python \
  --name py_task \
  --script "print('ok')" \
  --code 1001

cli-anything-dolphinscheduler --json task build-generic \
  --name spark_job \
  --task-type SPARK \
  --params-json '{"mainClass":"org.example.Job"}' \
  --code 1002
```

`task build-generic` is the escape hatch for any DolphinScheduler task plugin
that does not yet have a typed builder.

## Documentation

- [中文安装与使用说明](INSTALL.zh-CN.md)
- [English install guide](INSTALL.md)
- [GitHub 发布说明](PUBLISH.zh-CN.md)
- [Full command reference](cli_anything/dolphinscheduler/README.md)
- [AI skill](skills/cli-anything-dolphinscheduler/SKILL.md)

## Development

```bash
source .venv/bin/activate
python3 -m pytest cli_anything/dolphinscheduler/tests/test_core.py -v
CLI_ANYTHING_FORCE_INSTALLED=1 python3 -m pytest cli_anything/dolphinscheduler/tests/test_subprocess.py -v
```
