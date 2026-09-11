# sparks.nvim

基于物理粒子的 Neovim 输入反馈插件。动画可以固定在右侧或跟随真实光标，继承当前
语法颜色，支持 Combo、编辑器事件反馈和用户自定义特效，同时不会阻塞输入。

[English](README.md)

![sparks.nvim 光标粒子演示](assets/demo.gif)

## 主要特性

- 默认固定在右侧中部，也可固定在右上、右下或跟随光标。
- 光标模式的空白区域完全透明，不再用矩形背景遮挡代码。
- 内置 `subtle`、`power`、`zen`、`streamer` 四套风格预设。
- 正确处理中文、符号、Emoji 的显示宽度和高亮位置。
- 提供稳定的 `emit()` 和 `register_effect()` 公共接口。
- 可在保存、诊断错误清零、测试成功时触发反馈。
- Treesitter 智能着色、Combo 热度、屏幕震动和跨平台可选音效。
- 自适应窗口尺寸、粒子数量上限和自动停止的渲染循环。

## 要求与安装

- Neovim 0.10 或更高版本。
- Treesitter parser 是可选项；缺少时自动使用后备颜色。
- 声音默认关闭，可选使用 `afplay`、`paplay`、`aplay`、`ffplay`、
  PowerShell 或 `canberra-gtk-play`。

使用 lazy.nvim：

```lua
{
  "wsgggws/sparks.nvim",
  event = "VeryLazy",
  opts = {
    preset = "power",
  },
}
```

## 风格预设

| 预设 | 风格 | FPS | 粒子上限 | 删除反馈 | 震动 |
| --- | --- | ---: | ---: | --- | --- |
| `subtle` | 克制、轻微闪烁 | 24 | 80 | 关闭 | 关闭 |
| `power` | 平衡、有打击感 | 30 | 180 | 开启 | 开启 |
| `zen` | 缓慢飞雪和气泡 | 20 | 60 | 关闭 | 关闭 |
| `streamer` | 适合录屏和直播 | 60 | 400 | 开启 | 开启 |

显式配置会覆盖预设：

```lua
require("sparks").setup({
  preset = "subtle",
  position = "cursor",
  render = {
    radius = 5,
    avoid_completion_menu = true,
    transparent = true,
    show_text = false,
    combo_position = "top",
    safe_radius = { x = 1, y = 0 },
    offset = { x = 2, y = 1 },
  },
  max_particles = 100,
})
```

运行 `:SparksPreview` 可以依次预览全部已注册特效。

## 常用配置

```lua
require("sparks").setup({
  enabled = true,
  preset = "power",
  position = "right-center", -- top-right、right-center、bottom-right 或 cursor
  duration = 1200,
  throttle = 30,
  animation_fps = 30,
  max_particles = 180,
  particle_multiplier = 1,
  default_effect = { "confetti", "sparkle", "snow", "rain", "fizz" },

  render = {
    radius = 6,
    avoid_completion_menu = true,
    transparent = false, -- 固定位置默认 false；光标模式默认 true
    show_text = true, -- 固定位置默认 true；光标模式默认 false
    combo_position = "center", -- 光标模式默认 top；none 表示隐藏
    safe_radius = { x = 1, y = 0 }, -- 仅用于光标模式
    offset = { x = 2, y = 1 }, -- 仅用于光标模式
  },

  show_on_insert = true,
  show_on_delete = true,
  enable_combo = true,
  combo_threshold = 1,
  combo_timeout = 400,
  heat_map = {
    [10] = "rainbow",
    [20] = "fire",
  },
  enable_shake = true,
  shake_intensity = 1,

  triggers = {
    ["{"] = "explode",
    ["["] = "matrix",
    ["?"] = "sparkle",
    ["+"] = "fire",
    ["<"] = "heart",
  },

  enable_sound = false,
  sound_pack = "default", -- default 或 none
  sound_volume = 1,
  sound_file_insert = nil, -- 字符串或路径列表
  sound_file_delete = nil,

  ignore_paste = true,
  disable_on_macro = true,
  excluded_filetypes = { "TelescopePrompt", "NvimTree", "neo-tree", "lazy", "mason", "dashboard" },
  excluded_buftypes = { "nofile", "terminal", "prompt" },
  winblend = 0, -- 固定位置或 transparent=false 时生效

  integrations = {
    save = { enabled = false, effect = "sparkle", intensity = 1 },
    diagnostics_clear = { enabled = false, effect = "confetti", intensity = 2 },
    test_success = {
      enabled = false,
      effect = "fire",
      intensity = 3,
      user_events = { "SparksTestSuccess" },
    },
  },
})
```

`position` 是主要位置配置。固定位置默认使用不透明浮窗、显示事件文字、居中显示
Combo，并使用 `winblend`。设置 `position = "cursor"` 后会自动启用透明背景、隐藏
重复输入字符、把 Combo 放在顶部，并保护光标行中央的三个单元。`render.offset` 只
作用于光标模式，正数 `x` 向右、正数 `y` 向下。旧的
`render.mode = "cursor" | "corner"` 仍兼容，但新配置建议统一使用 `position`。只有未
显式配置对应 render 字段时才会使用模式默认值；显式配置始终优先。

完整默认配置和行为契约见英文 [README](README.md) 或 `:help sparks-config`。

## 公共接口

其他插件、映射或 autocmd 可以直接发射反馈：

```lua
local accepted, reason = require("sparks").emit({
  effect = "confetti",
  text = "PASS",
  intensity = 2,
  force = true,
  throttle = false,
})
```

成功时返回 `true`；拒绝时返回 `false`，原因是 `disabled`、`excluded`、
`throttled` 或 `unknown_effect`。

注册数据驱动特效：

```lua
require("sparks").register_effect("comet", {
  chars = { "*", ".", "+" },
  count = 8,
  life = { 20, 35 },
  gravity = 0.04,
  drag = 0.98,
  velocity = function(context)
    return (math.random() - 0.5) * 1.8, -0.8
  end,
})
```

测试工具各不相同，因此测试成功集成使用 `User` 事件：

```lua
vim.api.nvim_exec_autocmds("User", { pattern = "SparksTestSuccess" })
```

## 命令

- `:SparksToggle`：启用或禁用全部反馈；禁用时立即关闭浮窗。
- `:SparksTest` / `:SparksPreview`：依次预览所有已注册特效。
- `:checkhealth sparks`：检查版本、声音驱动、着色能力和渲染预算。

## 开发

```sh
make test
make lint
make benchmark
make demo
```

欢迎贡献新的 preset 和 effect，详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## License

MIT
