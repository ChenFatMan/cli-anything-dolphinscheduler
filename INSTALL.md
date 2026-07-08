# Install cli-anything-dolphinscheduler

Chinese guide: [INSTALL.zh-CN.md](INSTALL.zh-CN.md).

`cli-anything-dolphinscheduler` is a CLI-Anything harness for a running Apache
DolphinScheduler API server. It calls the real REST API; it does not reimplement
scheduling.

## AI Auto-Install Command

After this repository exists on GitHub, replace `<OWNER>` with the real GitHub owner:

```bash
REPO_URL="https://github.com/<OWNER>/cli-anything-dolphinscheduler.git"; INSTALL_DIR="${HOME}/.local/share/cli-anything-dolphinscheduler"; mkdir -p "$(dirname "$INSTALL_DIR")"; if [ -d "$INSTALL_DIR/.git" ]; then git -C "$INSTALL_DIR" pull --ff-only; else git clone "$REPO_URL" "$INSTALL_DIR"; fi && cd "$INSTALL_DIR" && chmod +x install.sh && ./install.sh --dev --verify --install-skill --install-bin --force-installed-tests
```

This installs:

- a local `.venv`
- the `cli-anything-dolphinscheduler` package
- an AI skill under `~/.codex/skills` and `~/.agents/skills`
- a stable launcher at `~/.local/bin/cli-anything-dolphinscheduler`

The same command is stored in `AI_INSTALL_COMMAND.txt`.

If already in the repository root:

```bash
chmod +x install.sh
./install.sh --dev --verify --force-installed-tests --install-skill --install-bin
```

## Manual Install

```bash
cd cli-anything-dolphinscheduler
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -e '.[dev]'
cli-anything-dolphinscheduler --version
```

Useful installer options:

```bash
./install.sh --help
./install.sh --verify
./install.sh --install-skill --install-bin --verify
./install.sh --venv /tmp/ds-cli-venv --verify
./install.sh --system --user --verify
```

## Configure DolphinScheduler Connection

Token auth:

```bash
export DS_URL=http://localhost:12345/dolphinscheduler
export DS_TOKEN=<access-token>
```

Username/password auth:

```bash
export DS_URL=http://localhost:12345/dolphinscheduler
export DS_USER=admin
export DS_PASSWORD=dolphinscheduler123
```

Persist config:

```bash
cli-anything-dolphinscheduler \
  --url http://localhost:12345/dolphinscheduler \
  --user admin \
  --password dolphinscheduler123 \
  config set
```

## Basic Use

```bash
cli-anything-dolphinscheduler --json project list
cli-anything-dolphinscheduler project use <project-name-or-code>
cli-anything-dolphinscheduler --json workflow list
```

Build task JSON without creating a workflow:

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

## For AI Agents

After `--install-skill`, a new AI session can discover the skill at:

```text
~/.codex/skills/cli-anything-dolphinscheduler/SKILL.md
~/.agents/skills/cli-anything-dolphinscheduler/SKILL.md
```

Use `--json` for machine-readable output. If `cli-anything-dolphinscheduler` is
not in `PATH`, call `~/.local/bin/cli-anything-dolphinscheduler`.

## GitHub

Standalone repository and push instructions: [GITHUB.md](GITHUB.md).

## Uninstall

```bash
python3 -m pip uninstall cli-anything-dolphinscheduler
rm -f ~/.local/bin/cli-anything-dolphinscheduler
rm -rf ~/.codex/skills/cli-anything-dolphinscheduler
rm -rf ~/.agents/skills/cli-anything-dolphinscheduler
```
