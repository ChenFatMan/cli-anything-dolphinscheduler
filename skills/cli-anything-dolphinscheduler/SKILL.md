---
name: cli-anything-dolphinscheduler
description: Structured CLI for a running Apache DolphinScheduler server. Drive projects, workflow definitions, runs, instances, cron schedules, and access tokens through the real REST API. Use when the user wants to manage or automate DolphinScheduler workflows from the command line or programmatically with --json output.
---

# cli-anything-dolphinscheduler

A command-line client to a **running** Apache DolphinScheduler API server. It maps
each command to the server's REST API (the same one the web UI uses) — it does
**not** reimplement scheduling. The server is a hard dependency.

## Prerequisites

- Python 3.8+
- A reachable DolphinScheduler API server (default `http://localhost:12345/dolphinscheduler`)
- Credentials: an access token, or a username + password

## Installation

```bash
cd cli-anything-dolphinscheduler
chmod +x install.sh
./install.sh --dev --verify --install-skill --install-bin --force-installed-tests
```

Verify:
```bash
cli-anything-dolphinscheduler --version
```

Manual install and usage details live in `INSTALL.md`.
Chinese install and usage details live in `INSTALL.zh-CN.md`.

## Connecting

Config resolves from CLI flags > env vars > config file > defaults.

```bash
# One-off with flags
cli-anything-dolphinscheduler \
  --url http://localhost:12345/dolphinscheduler \
  --user admin --password dolphinscheduler123 \
  project list

# Or via environment variables
export DS_URL=http://localhost:12345/dolphinscheduler
export DS_TOKEN=<access-token>          # preferred: stateless token auth
# (or DS_USER / DS_PASSWORD for session login)

# Persist to ~/.cli-anything-dolphinscheduler/config.json
cli-anything-dolphinscheduler --url ... --token ... config set
```

Auth uses the DolphinScheduler `token` HTTP header when a token is set, otherwise
it logs in with user/password to obtain a session cookie.

## Command Groups

| Group | Purpose |
|-------|---------|
| `project` | Create, list, select (persisted), delete projects |
| `task` | Build taskDefinitionJson entries for workflow DAGs, including generic task plugins |
| `workflow` | Create (from shell tasks), list, release ONLINE/OFFLINE, delete definitions |
| `run` | Trigger a run, control a running instance (STOP/PAUSE/rerun) |
| `instance` | List/delete workflow instances, inspect task instances, force-success or stop tasks |
| `schedule` | Create and list cron schedules |
| `token` | Create and list API access tokens |
| `config` / `login` | Inspect/persist config, verify credentials |

## Core Workflow: build and run a pipeline

```bash
# 1. Select (or create) a project — persisted in the session
cli-anything-dolphinscheduler project create "Analytics"
cli-anything-dolphinscheduler project use "Analytics"

# 2. Create a workflow from shell tasks.
#    Task spec is 'name:script' with optional ':dep1,dep2' upstream deps.
cli-anything-dolphinscheduler workflow create-shell \
  --name "ETL" \
  --task "extract:python extract.py" \
  --task "transform:python transform.py:extract" \
  --task "load:python load.py:transform" \
  --online

# Optional: build taskDefinitionJson entries directly for inspection or reuse
cli-anything-dolphinscheduler --json task build-python \
  --name "extract" \
  --script "print('extract')" \
  --code 1001

cli-anything-dolphinscheduler --json task build-generic \
  --name "spark_job" \
  --task-type SPARK \
  --params-json '{"mainClass":"org.example.Job"}' \
  --code 1002

# 3. Trigger a run (must be ONLINE)
cli-anything-dolphinscheduler run start "ETL"

# 4. Watch workflow and task instances
cli-anything-dolphinscheduler instance list --page-size 10
cli-anything-dolphinscheduler instance get <instance-id>
cli-anything-dolphinscheduler instance tasks <instance-id>
cli-anything-dolphinscheduler instance task-list --workflow-instance-id <instance-id>

# 5. Control a running workflow or task instance
cli-anything-dolphinscheduler run control <instance-id> STOP
cli-anything-dolphinscheduler instance stop-task <task-instance-id>
```

## Task Instance Troubleshooting

```bash
# Search failed tasks in the current project
cli-anything-dolphinscheduler --json instance task-list --state FAILURE

# Inspect tasks inside one workflow instance
cli-anything-dolphinscheduler --json instance tasks <workflow-instance-id>

# Mark a failed task as successful so recovery can proceed
cli-anything-dolphinscheduler instance force-task-success <task-instance-id>
```

## Scheduling

```bash
# Create a cron schedule (Quartz 6/7-field expression) and activate it
cli-anything-dolphinscheduler schedule create "ETL" \
  --crontab "0 0 3 * * ? *" --online

cli-anything-dolphinscheduler schedule list
```

## Task JSON Construction

Use `task build-*` when an agent needs to inspect or assemble
`taskDefinitionJson` explicitly instead of using the high-level
`workflow create-shell` shortcut. Typed builders exist for SHELL, PYTHON, SQL,
and HTTP. Use `task build-generic` for all other DolphinScheduler task plugins
by passing explicit `taskType` and `taskParams` JSON.

```bash
# Offline construction with typed builders
cli-anything-dolphinscheduler --json task build-shell \
  --name extract --script "python extract.py" --code 1001
cli-anything-dolphinscheduler --json task build-sql \
  --name query --sql "select 1" --datasource 10 --code 1002
cli-anything-dolphinscheduler --json task build-http \
  --name health --url "https://example.com/health" --code 1003

# Generic construction for plugin task types such as SPARK, FLINK, DATAX, K8S, etc.
cli-anything-dolphinscheduler --json task build-generic \
  --name spark_job --task-type SPARK \
  --params-json '{"mainClass":"org.example.Job"}' --code 1004

# Allocate a real code from the selected project, then render JSON
cli-anything-dolphinscheduler --json task build-shell \
  --name extract --script "python extract.py"
```

## REPL

Running with no subcommand enters an interactive session that keeps the selected
project and connection between commands:

```bash
cli-anything-dolphinscheduler
dolphinscheduler ❯ project use Analytics
dolphinscheduler ❯ workflow list
dolphinscheduler ❯ run start ETL
dolphinscheduler ❯ help
dolphinscheduler ❯ quit
```

## For AI Agents

1. **Resolve the command first** — use `cli-anything-dolphinscheduler` when it is
   in `PATH`; otherwise use `~/.local/bin/cli-anything-dolphinscheduler`, which
   is installed by `./install.sh --install-bin`.
2. **Always pass `--json`** for machine-readable output. Success responses are
   `{"success": true, "data": ...}`; errors are `{"success": false, "error": "...", "message": "..."}` on **stderr** with a non-zero exit code.
3. **Check the exit code** — non-zero means the command failed; parse stderr JSON
   for the reason (`error` gives a stable code like `api_error`, `auth_error`,
   `network_error`, `not_found`, `invalid_input`).
4. **Select a project once** with `project use <name>`; later commands reuse it
   from the session. Or pass `--project-code <code>` explicitly per command.
5. **Reference projects and workflows by name or numeric code** — both resolve.
6. **A workflow must be ONLINE before `run start`** — use `--online` at creation
   or `workflow release <name>`.
7. **Use `instance task-list` for failure triage** before mutating task state.
   It supports filters for workflow instance, task name/code, executor, state,
   host, date range, and `taskExecuteType`.
8. **Use `task build-* --json` to inspect Task construction**. Pass `--code`
   for offline JSON construction; omit `--code` to allocate the code from the
   real DolphinScheduler API. Use `build-generic` when no typed builder exists.

### JSON example

```bash
cli-anything-dolphinscheduler --json project list
```
```json
{
  "success": true,
  "data": [
    {"code": 12345678901234, "name": "Analytics", "userName": "admin"}
  ]
}
```

## Reference

- `README.md` — full command reference and troubleshooting
- `DOLPHINSCHEDULER.md` — complete REST API map for DolphinScheduler 3.4.2
- `tests/TEST.md` — test plan and results

## Version

1.0.0
