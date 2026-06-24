# 别按那个键 (Don't Press That Key)

> Godot 4.7 2D 塔防 | 桌面隐喻风格 | 纯 GDScript


## 项目结构

| 文档 | 用途 |
|---|---|
| [`docs/GDD.md`](docs/GDD.md) | 工程现状 — 类设计、系统设计、运行时行为 |
| [`CLAUDE.md`](CLAUDE.md) | 工程配置 — 输入映射、目录结构、全局组/类 |
| [`docs/IDEA.md`](docs/IDEA.md) | 个人创意草稿（非工程文档） |
| [`docs/TODO.md`](docs/TODO.md) | 任务列表 |

## 命名规范

| 对象 | 规则 | 示例 |
|---|---|---|
| 类名 / 节点名 / 全局脚本 / 全局组 | **PascalCase**（大驼峰） | `BaseClickedButton` `FailureButton` `BaseEnemy` |
| 文件名 (.gd / .tscn) | **snake_case**（小写下划线） | `base_button.gd` `base_enemy.tscn` |
| 变量名 | **snake_case**（小写下划线） | `click_times` `current_button` `animation_player` |
| 常量 / 枚举值 | **UPPER_SNAKE_CASE** | `MAX_WAVES`（暂未使用） |
| 信号命名 | **snake_case**（过去式/描述性） | `navigation_finished` `pressed` |
| 私有方法/变量 | 前缀 `_`（下划线） | `_ready()` `_physics_process()` `_on_xxx()` |
| 公共方法 | snake_case，无前缀 | `navigation()` `click()` `press()` `release()` |

## 协作规范

### 分支策略
- `main` — 始终可运行（Godot F5 不出错），禁止直接 push
- `feature/xxx` — 每人一个功能分支
- 所有改动通过 PR 提交到 `main`

### Commit 格式

```
<前缀>: <简短描述>
```

| 前缀 | 用途 |
|---|---|
| `feat:` | 新功能 |
| `fix:` | 修复 bug |
| `refactor:` | 重构（行为不变） |
| `rebuild:` | 重制(大幅的修改) |
| `art:` | 美术/音效资源 |
| `docs:` | 文档 |
| `chore:` | 杂项（配置、构建） |
| `description:` | 其他（提交描述） |

示例：

```
feat: BaseEnemy 纯随机寻路
fix: 导航目标在按钮释放后未更新
refactor: 按钮类型从枚举改为继承
art: 替换敌人鼠标光标精灵
docs: 更新 GDD 运行时行为章节
```

### 场景冲突避免
- `.tscn` 是文本格式，git 可 diff，但合并容易出错
- **一人一个场景** — 避免两人同时改同一个 `.tscn`
- 场景拆分要细 — 用 PackedScene 实例化，不要把一切塞 `main.tscn`
- 数据多用 `.tres`（Custom Resource），减少场景内嵌数据
- 出现冲突时优先用 Godot 编辑器重做，不要手动修 UID
