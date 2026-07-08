# cli-anything-dolphinscheduler

Structured CLI harness for Apache DolphinScheduler — a command-line client that drives the real DolphinScheduler REST API.

## What This Is

This CLI **does not reimplement scheduling**. It is a structured client to a *running* DolphinScheduler server, mapping every command to REST API calls exactly as the web UI does.

**Key features:**
- One-shot commands and interactive REPL mode
- `--json` output for agent consumption
- Stateful sessions (remembers current project)
- Complete coverage of projects, workflows, runs, instances, schedules, and tokens

## Installation

From this repository:

```bash
cd cli-anything-dolphinscheduler
chmod +x install.sh
./install.sh --dev --verify --install-skill --install-bin
```

For AI auto-install, see [`INSTALL.md`](../../INSTALL.md).
中文安装与使用说明见 [`INSTALL.zh-CN.md`](../../INSTALL.zh-CN.md)。

```bash
pip install cli-anything-dolphinscheduler
```

Or from source:
```bash
git clone <repo>
cd cli-anything-dolphinscheduler
pip install -e .
```

## Quick Start

### One-shot commands

```bash
# Configure connection (persisted)
cli-anything-dolphinscheduler --url http://localhost:12345/dolphinscheduler \
    --user admin --password dolphinscheduler123 \
    config set

# List projects
cli-anything-dolphinscheduler project list

# Select current project
cli-anything-dolphinscheduler project use MyProject

# List workflows in current project
cli-anything-dolphinscheduler workflow list

# Create a simple workflow
cli-anything-dolphinscheduler workflow create-shell \
    --name "ETL Pipeline" \
    --task "extract:python extract.py" \
    --task "load:python load.py:extract" \
    --online

# Build taskDefinitionJson entries without creating a workflow
cli-anything-dolphinscheduler --json task build-python \
    --name extract \
    --script "print('extract')" \
    --code 1001

cli-anything-dolphinscheduler --json task build-generic \
    --name spark_job \
    --task-type SPARK \
    --params-json '{"mainClass":"org.example.Job"}' \
    --code 1002

# Trigger a run
cli-anything-dolphinscheduler run start "ETL Pipeline"

# Query workflow and task instances
cli-anything-dolphinscheduler instance list --page-size 10
cli-anything-dolphinscheduler instance tasks <instance-id>
cli-anything-dolphinscheduler instance task-list --workflow-instance-id <instance-id>
```

### Interactive REPL

```bash
cli-anything-dolphinscheduler
# No subcommand → drops into REPL

dolphinscheduler> project list
dolphinscheduler> project use Demo
dolphinscheduler> workflow list
dolphinscheduler> help
dolphinscheduler> quit
```

### JSON output for agents

Every command supports `--json` for machine-readable output:

```bash
cli-anything-dolphinscheduler --json project list
```

Returns:
```json
{
  "success": true,
  "data": [
    {"code": 123, "name": "Demo", "userName": "admin", "workflowDefinitionCount": 5}
  ]
}
```

## Configuration

Connection settings are resolved in this order (highest wins):

1. CLI flags: `--url`, `--token`, `--user`, `--password`
2. Environment variables: `DS_URL`, `DS_TOKEN`, `DS_USER`, `DS_PASSWORD`
3. Config file: `~/.cli-anything-dolphinscheduler/config.json`
4. Built-in defaults: `http://localhost:12345/dolphinscheduler`

Save current config:
```bash
cli-anything-dolphinscheduler --url http://prod:12345 --token <token> config set
```

## Command Groups

### project
Create, list, select, and delete projects.

```bash
project create <name> [--description TEXT]
project list [--search TEXT]
project use <name-or-code>
project current
project delete <name-or-code>
```

### workflow
Manage workflow definitions.

```bash
workflow list [--project-code INT]
workflow create-shell --name TEXT --task "name:script" [--online]
workflow release <name-or-code> [--offline]
workflow delete <name-or-code>
```

Task spec format: `name:script` or `name:script:dep1,dep2`

Example:
```bash
workflow create-shell --name "Pipeline" \
    --task "extract:python extract.py" \
    --task "transform:python transform.py:extract" \
    --task "load:python load.py:transform" \
    --online
```

### task
Build task-definition JSON for workflow DAGs.

```bash
task build-generic --name TEXT --task-type TEXT --params-json JSON [--code INT]
task build-shell --name TEXT --script TEXT [--code INT]
task build-python --name TEXT --script TEXT [--code INT]
task build-sql --name TEXT --sql TEXT --datasource INT [--code INT]
task build-http --name TEXT --url URL [--method GET|POST|PUT|DELETE|HEAD] [--code INT]
```

The typed builders cover high-frequency task types: SHELL, PYTHON, SQL, and
HTTP. `task build-generic` is the escape hatch for every other DolphinScheduler
task plugin: pass the exact `taskType` and `taskParams` JSON expected by the
real server/plugin. Pass `--code` for offline JSON construction; omit it to
allocate a real task code from `/projects/{code}/task-definition/gen-task-codes`
using the selected project or `--project-code`.

### run
Trigger and control workflow execution.

```bash
run start <name-or-code> [--dry-run]
run control <instance-id> <action>
```

Actions: `STOP`, `PAUSE`, `REPEAT_RUNNING`, `RECOVER_SUSPENDED_PROCESS`

### instance
Query workflow and task instances.

```bash
instance list [--page-size INT]
instance get <instance-id>
instance delete <instance-id>
instance tasks <instance-id>
instance task-list [--workflow-instance-id INT] [--task-name TEXT] [--state TEXT]
instance force-task-success <task-instance-id>
instance stop-task <task-instance-id>
```

`instance tasks` returns the task list embedded under one workflow instance.
`instance task-list` searches task instances across the current project and
supports filters for workflow instance, workflow definition, task name/code,
executor, state, host, date range, and task execute type.

### schedule
Manage cron schedules.

```bash
schedule create <name-or-code> --crontab "0 0 3 * * ? *" [--online]
schedule list
```

Crontab format: Quartz cron expression (6 or 7 fields)

### token
Manage API access tokens.

```bash
token create --user-id INT --expire-time "2030-01-01 00:00:00"
token list
```

### config & login

```bash
config show           # Show current config (secrets masked)
config set            # Save current config to file
login                 # Verify credentials
```

## Session State

The CLI persists a small session file (`~/.cli-anything-dolphinscheduler/session.json`) that remembers:
- Current project code and name

This lets you omit `--project-code` on every command once you've selected a project.

## Development

### Run tests

```bash
# Unit tests (no server required)
pytest -v cli_anything/dolphinscheduler/tests/test_core.py

# E2E tests (requires running server)
pytest -v -m e2e cli_anything/dolphinscheduler/tests/test_full_e2e.py

# Subprocess tests (CLI must be installed)
pip install -e .
export CLI_ANYTHING_FORCE_INSTALLED=1
pytest -v cli_anything/dolphinscheduler/tests/test_subprocess.py
```

### Test coverage

```bash
pytest --cov=cli_anything.dolphinscheduler \
       --cov-report=term-missing \
       --cov-report=html
```

## Architecture

```
cli_anything/
└── dolphinscheduler/
    ├── dolphinscheduler_cli.py    # Main CLI entry point
    ├── core/
    │   ├── client.py              # HTTP client + error handling
    │   ├── config.py              # Layered config resolution
    │   ├── session.py             # Stateful session (current project)
    │   ├── projects.py            # Project operations
    │   ├── workflows.py           # Workflow definitions + DagBuilder
    │   ├── executors.py           # Start / control runs
    │   ├── instances.py           # Query instances
    │   ├── schedules.py           # Cron schedules
    │   └── tokens.py              # Access tokens
    ├── utils/
    │   ├── output.py              # --json vs human-readable output
    │   └── repl_skin.py           # Branded prompt + tables
    └── tests/
        ├── test_core.py           # Unit tests (20 tests, all pass)
        ├── test_full_e2e.py       # E2E tests (requires server)
        └── test_subprocess.py     # Subprocess tests (4/5 pass)
```

## API Coverage

This CLI covers the essential DolphinScheduler REST API surface:

- `/projects` — CRUD operations
- `/projects/{code}/workflow-definition` — workflow definitions
- `/projects/{code}/task-definition/gen-task-codes` — server-side task code allocation for taskDefinitionJson
- `/projects/{code}/executors` — start / control runs
- `/projects/{code}/workflow-instances` — query/delete workflow instances and list their tasks
- `/projects/{code}/task-instances` — query task instances, force-success failed tasks, stop running tasks
- `/projects/{code}/schedules` — cron schedules
- `/access-tokens` — API tokens

For the complete API map, see [DOLPHINSCHEDULER.md](../../DOLPHINSCHEDULER.md).

## Troubleshooting

### Connection refused
Verify the server is running and reachable:
```bash
curl http://localhost:12345/dolphinscheduler/ui
```

### Authentication failed (401)
- Check credentials: `cli-anything-dolphinscheduler login`
- Or mint a token: `cli-anything-dolphinscheduler token create --user-id 1 --expire-time "2030-01-01 00:00:00"`

### No project selected
Select a project first:
```bash
cli-anything-dolphinscheduler project use <name>
```

Or pass `--project-code` on every command.

## References

- [DOLPHINSCHEDULER.md](../../DOLPHINSCHEDULER.md) — Complete REST API map for DolphinScheduler 3.4.2
- [tests/TEST.md](tests/TEST.md) — Test plan and results
- [Apache DolphinScheduler Docs](https://dolphinscheduler.apache.org/en-us/docs/latest)

## License

Apache License 2.0
