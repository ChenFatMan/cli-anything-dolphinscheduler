# Codex / AI Agent 使用手册

这份文档给 AI agent 读。目标是让 agent 安装后能直接连接 DolphinScheduler，执行真实 API 操作，并清楚知道能力边界。

参考的公开 agent/skill 文档模式：README 只做入口，SKILL 负责触发和短决策，详细操作放到 runbook；所有关键路径给复制即用命令；失败路径必须有明确退出码和排查命令。

## 一句话结论

可以直接安装给 Codex 使用。只要 DolphinScheduler API Server 可访问，并配置了 `DS_URL` 加 `DS_TOKEN` 或 `DS_USER` / `DS_PASSWORD`，Codex 就能调用 `cli-anything-dolphinscheduler` 创建项目、管理资源中心文件、创建并运行 shell 工作流、构造非 shell task JSON、查询实例和排查失败。

## 给 Codex 的任务模板

把下面这段交给 Codex，可以让它自己安装、验证并开始操作：

```text
请安装 cli-anything-dolphinscheduler，并使用真实 DolphinScheduler API 操作。

安装命令：
REPO_URL="git@github.com:ChenFatMan/cli-anything-dolphinscheduler.git"; INSTALL_DIR="${HOME}/.local/share/cli-anything-dolphinscheduler"; mkdir -p "$(dirname "$INSTALL_DIR")"; if [ -d "$INSTALL_DIR/.git" ]; then git -C "$INSTALL_DIR" pull --ff-only; else git clone "$REPO_URL" "$INSTALL_DIR"; fi && cd "$INSTALL_DIR" && chmod +x install.sh && ./install.sh --dev --verify --install-skill --install-bin --force-installed-tests

连接配置：
export DS_URL=http://localhost:12345/dolphinscheduler
export DS_TOKEN=<access-token>

如果没有 token，则使用：
export DS_USER=admin
export DS_PASSWORD=dolphinscheduler123

执行规则：
1. 所有非交互命令加 --json。
2. 非零退出码代表失败，读取 stderr JSON。
3. 不要伪造 DolphinScheduler 成功结果。
4. 每次完成操作后报告执行过的命令、返回的 code/id/fullName/instance_id。
```

## 安装和验证

一条命令安装：

```bash
REPO_URL="git@github.com:ChenFatMan/cli-anything-dolphinscheduler.git"; INSTALL_DIR="${HOME}/.local/share/cli-anything-dolphinscheduler"; mkdir -p "$(dirname "$INSTALL_DIR")"; if [ -d "$INSTALL_DIR/.git" ]; then git -C "$INSTALL_DIR" pull --ff-only; else git clone "$REPO_URL" "$INSTALL_DIR"; fi && cd "$INSTALL_DIR" && chmod +x install.sh && ./install.sh --dev --verify --install-skill --install-bin --force-installed-tests
```

安装后检查：

```bash
cli-anything-dolphinscheduler --version
cli-anything-dolphinscheduler --help
cli-anything-dolphinscheduler resource --help
cli-anything-dolphinscheduler task --help
```

如果命令不在 `PATH`：

```bash
~/.local/bin/cli-anything-dolphinscheduler --version
```

## 连接配置

优先使用 token：

```bash
export DS_URL=http://localhost:12345/dolphinscheduler
export DS_TOKEN=<access-token>
```

或者使用用户名密码：

```bash
export DS_URL=http://localhost:12345/dolphinscheduler
export DS_USER=admin
export DS_PASSWORD=dolphinscheduler123
```

验证连接：

```bash
cli-anything-dolphinscheduler login
cli-anything-dolphinscheduler --json project list
```

持久化配置：

```bash
cli-anything-dolphinscheduler \
  --url http://localhost:12345/dolphinscheduler \
  --token <access-token> \
  config set
```

## 能力矩阵

| 目标 | 当前状态 | 命令 |
|------|----------|------|
| 创建/选择项目 | 已支持 | `project create`, `project use`, `project list` |
| 管理资源中心文件 | 已支持 | `resource base-dir/list/mkdir/create-file/upload/view/update-content/replace/download/delete` |
| 创建 shell 工作流 | 已支持 | `workflow create-shell` |
| 构造 Python/SQL/HTTP task JSON | 已支持 | `task build-python`, `task build-sql`, `task build-http` |
| 构造任意插件 task JSON | 已支持 | `task build-generic` |
| 运行工作流 | 已支持 | `run start` |
| 查询实例和任务失败 | 已支持 | `instance list`, `instance tasks`, `instance task-list` |
| 定时调度 | 已支持 | `schedule create`, `schedule list` |
| API token | 已支持 | `token create`, `token list` |
| 数据源管理 | 未封装 | 目前只能在 SQL task 里引用已有 datasource id |
| 高层非 shell 工作流创建 | 未封装 | 需要先用 `task build-*` 构造 JSON，再按 DolphinScheduler API 形状组装 |

## 标准操作顺序

### 1. 创建项目

```bash
cli-anything-dolphinscheduler --json project create "AgentProject"
cli-anything-dolphinscheduler project use "AgentProject"
cli-anything-dolphinscheduler --json project current
```

### 2. 创建资源中心文件

先拿根目录：

```bash
cli-anything-dolphinscheduler --json resource base-dir
```

创建脚本文件：

```bash
cli-anything-dolphinscheduler --json resource create-file \
  --name hello.py \
  --current-dir <directory-full-name> \
  --content "print('hello')"
```

上传本地文件：

```bash
cli-anything-dolphinscheduler --json resource upload \
  --path ./job.py \
  --current-dir <directory-full-name>
```

查看资源：

```bash
cli-anything-dolphinscheduler --json resource list --full-name <directory-full-name>
cli-anything-dolphinscheduler --json resource view <file-full-name>
```

### 3. 创建并运行 shell 工作流

```bash
cli-anything-dolphinscheduler workflow create-shell \
  --name "agent_smoke" \
  --task "hello:echo hello" \
  --online

cli-anything-dolphinscheduler --json run start "agent_smoke"
```

### 4. 构造非 shell task JSON

Python task：

```bash
cli-anything-dolphinscheduler --json task build-python \
  --name py_task \
  --script "print('ok')" \
  --code 1001
```

SQL task，引用已有数据源 ID：

```bash
cli-anything-dolphinscheduler --json task build-sql \
  --name query_task \
  --sql "select 1" \
  --datasource 10 \
  --datasource-type MYSQL \
  --code 1002
```

任意插件 task：

```bash
cli-anything-dolphinscheduler --json task build-generic \
  --name spark_job \
  --task-type SPARK \
  --params-json '{"mainClass":"org.example.Job"}' \
  --code 1003
```

规则：

- 有 `--code`：离线构造 JSON，不访问 server 分配 task code。
- 无 `--code`：需要当前项目或 `--project-code`，CLI 会请求 server 分配真实 task code。
- `build-generic` 不猜参数，`--params-json` 必须匹配真实 DolphinScheduler task plugin。

### 5. 排查运行失败

```bash
cli-anything-dolphinscheduler --json instance list --page-size 10
cli-anything-dolphinscheduler --json instance tasks <workflow-instance-id>
cli-anything-dolphinscheduler --json instance task-list --state FAILURE
```

必要时人工控制：

```bash
cli-anything-dolphinscheduler --json run control <workflow-instance-id> STOP
cli-anything-dolphinscheduler --json instance stop-task <task-instance-id>
cli-anything-dolphinscheduler --json instance force-task-success <task-instance-id>
```

## 数据源当前边界

当前没有 `datasource` 命令组，所以不能通过本 CLI 创建、测试连接、更新、删除 DolphinScheduler 数据源。

已支持的是在 SQL task 中引用已有数据源：

```bash
cli-anything-dolphinscheduler --json task build-sql \
  --name query_task \
  --sql "select 1" \
  --datasource <existing-datasource-id>
```

如果任务要求“创建数据源”，agent 必须明确说明当前 CLI 未封装该能力，不能假装已创建。后续要补齐时，应新增 `core/datasources.py` 和 `datasource` 命令组。

## 失败处理规则

| 错误 | 含义 | 处理 |
|------|------|------|
| `auth_error` | token 或账号密码无效 | 重新配置 `DS_TOKEN` 或 `DS_USER` / `DS_PASSWORD` |
| `network_error` | 访问不到 API server | 检查 `DS_URL`、端口和服务状态 |
| `invalid_input` | CLI 参数不合法 | 修正参数，不要重试同一命令 |
| `api_error` | DolphinScheduler server 拒绝请求 | 按 server 返回 message 修复 |
| `filesystem_error` | 本地读写文件失败 | 检查本地路径和权限 |

JSON 错误在 stderr，例如：

```json
{
  "success": false,
  "error": "api_error",
  "message": "Project not found"
}
```

## Agent 输出要求

Agent 完成任务时必须报告：

- 执行过的关键命令。
- 每条关键命令是否退出码为 0。
- 创建出的 `project_code`、`workflow_code`、`fullName`、`instance_id` 等标识。
- 如果失败，贴出 stderr JSON 的 `error` 和 `message`。
- 没有跑通的能力边界必须明说，不能用“应该可以”代替验证。

## 不要做

- 不要在没有退出码 0 的情况下说创建成功。
- 不要把 Resource Center 文件创建等同于 task `resourceList` 已绑定。
- 不要猜 datasource id；必须来自真实 DolphinScheduler。
- 不要把 `task build-generic` 当成参数推断器。
- 不要把 token、密码写进 README 或提交到 git。
