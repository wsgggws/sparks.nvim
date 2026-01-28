# Sparks.nvim

Neovim 插件：极具打击感的输入动画特效系统。

🔥 **粒子物理引擎** | **Combo 连击系统** | **沉浸式音效** | **智能着色**

> "写代码从未如此带感！"

<div align="center">
  <img src="assets/sparks-demo.gif" width="100%" />
</div>

[English Docs](README.en.md)

## ✨ 特性

- **⚛️ 物理粒子系统**：基于重力、阻力和初速度的实时粒子模拟，拒绝呆板的预制动画。
- **🔥 Combo 连击系统**：
  - 连续输入积累热度，触发 `x10` 连击显示。
  - **热度升级**：连击数越高，特效越炫酷（彩虹模式 🌈 -> 火焰模式 🔥）。
- **🎨 智能着色**：利用 Treesitter 自动识别当前语法的颜色，让烟花与代码融为一体。
- **💥 屏幕震动**：高能时刻触发屏幕震动，打击感拉满（可选）。
- **📱 自适应布局**：
  - 根据窗口大小自动调整动画窗口尺寸，完美适配小屏/大屏
  - 实时响应窗口大小变化，分屏调整时自动重新定位
  - 动画窗口跟随当前编辑窗口，切换窗口时自动适配
- **🎭 多种动画预设**：
  - `confetti` (彩带) - 默认输入
  - `explode` (爆炸) - 删除字符
  - `matrix` (黑客帝国) - 绿色代码雨
  - `snow` (飞雪) - 舒缓飘落
  - `rain` (雨滴) - 蓝色雨帘
  - `fizz` (气泡) - 向上冒泡
  - `fire` (火焰) - 向上升腾
  - `heart` (爱心) - 飘起的爱心
- **🔊 沉浸音效**：
  - 通过 `sound_pack` 一键切换音效主题（机械键盘、科幻等）
  - 智能节流优化，80ms 内相同音效只播放一次，避免卡顿
  - **macOS 专属优化**：使用 `afplay` 变速播放 (+250% 速率)，模拟极短促机械轴手感。
- **⚡ 极致性能**：
  - **✨ 视觉淡出**：粒子生命周期结束时会逐渐缩小变淡，细节感拉满。
  - **🛡️ 智能屏蔽**：自动在 Telescope、NvimTree、Terminal 等窗口禁用，专注核心编辑。
  - **🧩 智能复用**：复用窗口、Paste 模式检测、宏录制检测，零干扰。

## 📦 安装

### LazyVim / lazy.nvim

```lua
{
  "wsgggws/sparks.nvim",
  event = "VeryLazy",
  opts = {
    -- 🚀 默认已启用所有最佳配置
  },
}
```

## ⚙️ 配置手册

```lua
require("sparks").setup({
  -- 基础开关
  enabled = true,
  position = "top-right", -- 动画显示位置（会根据屏幕大小自动调整）

  -- 🚀 物理粒子系统配置
  animation_fps = 30,     -- 帧率 (建议 30-60)
  default_effect = { "confetti", "sparkle", "snow", "rain", "fizz" }

  -- 🔥 Combo 系统
  enable_combo = true,
  combo_threshold = 1,    -- 多少连击开始显示计数
  combo_timeout = 400,    -- 连击断开时间(ms)

  -- 热度映射：连击数 -> 特效模式
  heat_map = {
    [10] = "rainbow", -- >10 连击：七彩粒子
    [20] = "fire",    -- >20 连击：火焰升腾
  },

  -- 🫨 打击感
  enable_shake = true,    -- 连击爆发时窗口震动

  -- 输入/删除特效开关
  show_on_insert = true,  -- 输入字符时显示动画
  show_on_delete = true,  -- 删除字符时显示动画（仅插入模式）

  -- 动画预设
  -- 基础: confetti, explode, matrix, snow, rain, fizz, fire, heart, sparkle
  
  -- ⌨️ 高级触发器 (按键 -> 动画类型)
  triggers = {
    ["{"] = "explode",   -- 爆炸
    ["("] = "confetti",  -- 彩带
    ["["] = "matrix",    -- 黑客帝国
    ["!"] = "explode",   -- 爆炸
    ["?"] = "sparkle",   -- 闪烁
    ["="] = "fizz",      -- 气泡
    [";"] = "rain",      -- 雨滴
    [":"] = "rain",      -- 雨滴
    ["+"] = "fire",      -- 火焰
    ["<"] = "heart",     -- 爱心
    ["%"] = "confetti",  -- 彩带
  },

  -- 🔊 声音配置
  enable_sound = true,    -- 启用声音
  sound_on_insert = true, -- 输入时播放声音
  sound_on_delete = true, -- 删除时播放声音
  sound_volume = 5.0,     -- 音量 (0.0 - 5.0)
  sound_pack = "default", -- default, mechanical, sci-fi
  -- 声音会自动节流（80ms），避免快速操作时卡顿

  -- 🛡️ 智能屏蔽 (列表中的窗口不触发动画)
  excluded_filetypes = { "TelescopePrompt", "NvimTree", "neo-tree", "lazy", "mason" },
  excluded_buftypes = { "nofile", "terminal", "prompt" },

  -- 性能优化
  throttle = 100,         -- 节流时间(ms)，防止过度触发
  ignore_paste = true,    -- 粘贴模式时禁用
  disable_on_macro = true,-- 录制/执行宏时禁用

  -- 外观
  winblend = 0,           -- (0-100) 设置透明度，解决遮挡 CursorLine 背景问题
})
```

## 🎮 命令

- `:SparksToggle` - 切换插件开关
- `:SparksTest` - 测试动画效果
- `:checkhealth sparks` - 诊断配置健康状态

## 🔊 声音支持

- **macOS**: `afplay`
- **Linux**: `paplay` (PulseAudio), `aplay` (ALSA)
- **Windows**: PowerShell SoundPlayer

```lua
opts = {
  enable_sound = true,
  sound_file_insert = { "C:\\Windows\\Media\\Windows Ding.wav" },
  sound_file_delete = { "C:\\Windows\\Media\\Windows Error.wav" },
}
```

### Linux 用户配置示例

```lua
opts = {
  enable_sound = true,
  -- 使用 freedesktop 音效或自己的音频文件
  sound_file_insert = { "/usr/share/sounds/freedesktop/stereo/message.oga" },
  sound_file_delete = { "/usr/share/sounds/freedesktop/stereo/bell.oga" },
}
```

**注意**:

- 声音默认关闭，需要手动设置 `enable_sound = true`
- 如果不配置声音文件，将自动使用系统默认音效
- 支持多个声音文件，每次随机播放增加趣味性
- 建议戴耳机使用，音量不宜过大

## 🎨 自定义样式

动画使用的高亮组：

- 输入：`String`
- 删除：`WarningMsg`

可通过设置这些高亮组来自定义颜色。

## 🚀 性能

- 使用节流机制避免频繁触发（输入节流 100ms，声音节流 50ms）
- 异步窗口管理，不阻塞编辑
- 自动清理资源
- **自适应窗口尺寸**：
  - 根据窗口宽度实时调整大小：
    - 小窗口 (< 40 列)：16x8 窗口
    - 中等窗口 (40-60 列)：20x10 窗口
    - 大窗口 (> 60 列)：26x12 窗口
  - 窗口大小变化时自动重新定位
  - 切换编辑窗口时自动适配新窗口

## 📄 License

MIT
