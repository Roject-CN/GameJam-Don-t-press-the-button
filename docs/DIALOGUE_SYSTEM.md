# 对话系统

## 接入

关卡场景加两个节点：

- `DialogueManager`（Node）+ `dialogue_manager.gd`，`dialogue_box_scene` 指向 `dialogue_box.tscn`
- `DialogueTrigger`（Node）+ `dialogue_trigger.gd`，AUTO 模式，指向 Manager 和 `.tres` 序列

## DialogueLine 字段

| 字段 | 说明 | 默认值 |
|---|---|---|
| `speaker_name` | 说话人，留空 = 旁白 | `""` |
| `text` | 正文，支持 BBCode | `""` |
| `text_speed` | 打字速度（秒/字），0 = 瞬间 | `0.05` |
| `box_position` | 对话框屏幕坐标 | `(40, 520)` |
| `auto_advance` | 0 = 点击推进，>0 = 自动推进 | `0` |
| `tooltip_position` | 指示框起始坐标 | `(560, 280)` |
| `tooltip_size` | **非零即触发指示框** | `(0, 0)` |
| `tooltip_end_position` | 留空 = 静态；非零 = 动态滑动 | `(0, 0)` |

## 指示框

### 静态（`tooltip_end_position` 留空）

| 操作 | 效果 |
|---|---|
| 点击框内 | 关闭 + **推进对话** |
| 点击框外 | 封锁，无反应 |

### 动态（`tooltip_end_position` 非零）

循环：起点停顿 → 滑动到终点 → 终点停顿 → 消失回起点。

| 操作 | 效果 |
|---|---|
| 起点按下 → 终点松手 | 关闭 |
| 点击其他 | 封锁，无反应 |

### 配置（DialogueBox 导出）

| 属性 | 说明 | 默认值 |
|---|---|---|
| `indicator_color` | 颜色 | `(1, 0, 0, 0.5)` |
| `indicator_move_duration` | 滑动时长 | `1.5` |
| `indicator_pause_duration` | 起止停顿时长 | `0.3` |
| `enable_camera_focus` | 相机聚焦 | `true` |
| `camera_target_zoom` | 缩放倍数 | `(2, 2)` |

## 示例 .tres

```gdscript
[sub_resource type="Resource" id="line_0"]
script = ExtResource("2_line")
speaker_name = "NPC"
text = "看那个红色方块。"

[sub_resource type="Resource" id="line_1"]
script = ExtResource("2_line")
text = ""                              # 旁白
tooltip_position = Vector2(300, 200)   # 静态指示框
tooltip_size = Vector2(80, 80)

[sub_resource type="Resource" id="line_2"]
script = ExtResource("2_line")
speaker_name = "NPC"
text = "它滑过去了。"
tooltip_position = Vector2(200, 400)   # 动态指示框
tooltip_size = Vector2(80, 80)
tooltip_end_position = Vector2(900, 400)

[resource]
script = ExtResource("1_seq")
sequence_id = "demo"
lines = Array[...]([...])
```

## 文件

```
scripts/dialogues/   dialogue_line.gd  dialogue_sequence.gd  dialogue_manager.gd  dialogue_trigger.gd
scripts/ui/          dialogue_box.gd
scenes/ui/dialogue/  dialogue_box.tscn
resources/dialogues/ *.tres
```
