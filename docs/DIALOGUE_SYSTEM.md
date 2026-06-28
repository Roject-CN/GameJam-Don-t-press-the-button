# 对话系统使用文档

## 快速开始

### 1. 在关卡中接入

在关卡 `.tscn` 场景中添加两个节点：

- **DialogueManager** — `Node` 节点，挂 `dialogue_manager.gd`，`dialogue_box_scene` 指向 `dialogue_box.tscn`
- **DialogueTrigger** — `Node` 节点，挂 `dialogue_trigger.gd`，设为 `AUTO` 模式，指向上面的 DialogueManager 和你的对话 `.tres`

运行即自动弹出对话。

### 2. 编写对话内容

新建 `DialogueSequence` 资源（`.tres`），在编辑器中逐行填写：

| 字段 | 说明 | 默认值 |
|---|---|---|
| `speaker_name` | 说话人，留空 = 旁白（隐藏名字栏） | `""` |
| `text` | 对话正文，支持 BBCode | `""` |
| `text_speed` | 打字速度（秒/字），0 = 瞬间显示 | `0.05` |
| `box_position` | 对话框屏幕坐标 | `(40, 520)` |
| `auto_advance` | 0 = 点击推进，>0 = 显示完 N 秒自动下一条 | `0` |

BBCode 示例：`"小心那个[color=red]红色按钮[/color]！"`

### 3. 三种触发方式

| 模式 | 行为 |
|---|---|
| `AUTO` | 场景加载后 `auto_delay` 秒自动播放 |
| `SIGNAL` | 连接外部信号，收到信号时播放 |
| `MANUAL` | 其他脚本调用 `$DialogueTrigger.trigger()` |

代码触发：
```gdscript
$DialogueManager.trigger_sequence(preload("res://resources/dialogues/xxx.tres"))
```

## 运行时交互

| 操作 | 效果 |
|---|---|
| 左键点击（打字中） | 立即显示全文 |
| 左键点击（打完） | 推进到下一条 |
| 最后一条 + 点击 | 对话框消失 |

## 节点结构

```
DialogueBox (CanvasLayer, layer=128)
  └── Panel
        ├── VBoxContainer
        │     ├── TopBar (HBoxContainer)
        │     │     ├── LeftSpacer (12px)
        │     │     ├── SpeakerLabel
        │     │     └── Spacer
        │     ├── HSeparator
        │     └── MarginSpacer → TextLabel (RichTextLabel)
        └── NextIndicator ("▼")
```

旁白模式（`speaker_name=""`）时 TopBar + 分隔线自动隐藏。

## 自定义外观

`DialogueBox` 脚本导出属性，可在编辑器中调整：

| 属性 | 说明 |
|---|---|
| `panel_bg_color` | 对话框背景色 |
| `speaker_color` | 说话人名字颜色 |
| `text_color` | 正文颜色 |
| `next_indicator_blink_interval` | 继续箭头闪烁间隔 |

## 镜头联动（预留）

每条 `DialogueLine` 携带 `camera_target` / `camera_offset` / `camera_zoom` 字段（当前不消费）。`DialogueBox` 每行显示时发射 `line_displayed(index)` 信号，未来镜头系统监听即可驱动。

## 文件清单

```
scripts/dialogues/
├── dialogue_line.gd        单条对话 Resource
├── dialogue_sequence.gd    对话序列 Resource
├── dialogue_manager.gd     生命周期管理
└── dialogue_trigger.gd     触发桥接

scripts/ui/
└── dialogue_box.gd         对话框 CanvasLayer

scenes/ui/
└── dialogue_box.tscn        对话框场景

resources/dialogues/
├── tutorial_welcome.tres    示例：教程开场
├── tutorial_before_wave1.tres  示例：波次提示
└── cinematic_intro.tres     示例：多角色小剧场
```
