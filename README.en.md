# Sparks.nvim

The most satisfying typing effects plugin for Neovim.

🔥 **Particle Physics Engine** | **Combo System** | **Immersive Sound** | **Smart Colors**

> "Coding has never been this addictive!"

[中文文档](README.md)

## ✨ Features

- **⚛️ Physics Particle System**: Real-time simulation with gravity and drag.
  No boring pre-rendered animations.
- **🔥 Combo System**:
  - Accumulate heat with continuous typing to trigger `x10` combo counters.
  - **Heat Modes**: The higher the combo, the cooler the effects
    (`Rainbow 🌈` -> `Fire 🔥`).
- **🎨 Smart Coloring**: Automatically extracts colors from Treesitter to match
  your code's highlighting.
- **💥 Screen Shake**: Optional screen shake on high-combo moments or deletions
  for extra impact.
- **🎭 Diverse Effects**:
  - `confetti` (Default)
  - `explode` (On delete)
  - `matrix` (The Matrix style green rain)
  - `snow` (Gentle falling snow)
  - `fire` (Rising flames)
  - `heart` (Floating love hearts ♥)
  - `sparkle` (Twinkling stars ✦)
- **🔊 Immersive Sound**: Switch sound packs instantly
  (`default`, `mechanical`, `sci-fi`).
- **⚡ Extreme Performance**:
  - **✨ Visual Fading**: Particles shrink and fade out naturally.
  - **🛡️ Smart Exclude**: Disabled in Telescope, NvimTree, etc.
  - **Note**: Fully async rendering, zero blocking.

## 📦 Installation

### LazyVim / lazy.nvim

```lua
{
  "wsgggws/sparks.nvim",
  event = "VeryLazy",
  opts = {
    -- 🚀 All best configs enabled by default
  },
}
```

## ⚙️ Configuration

```lua
require("fireworks").setup({
  -- Basic
  enabled = true,
  position = "top-right",

  -- 🚀 Physics
  animation_fps = 30,     -- (Recommend 30-60)

  -- 🔥 Combo
  enable_combo = true,
  combo_threshold = 5,    -- Start counter after 5 keystrokes
  combo_timeout = 2000,   -- Reset after 2s idle

  -- Heat Map: Combo -> Mode
  heat_map = {
    [10] = "rainbow", -- >10: Rainbow particles
    [20] = "fire",    -- >20: Rising fire
  },

  -- 🫨 Impact
  enable_shake = true,    -- Screen shake on big combos

  -- ⌨️ Triggers (Key -> Effect)
  triggers = {
    ["{"] = "explode",
    ["("] = "confetti",
    ["!"] = "explode",
    ["*"] = "snow",
    ["^"] = "fire",
    ["}"] = "matrix",
    ["?"] = "sparkle",
    ["<"] = "heart",
    [">"] = "heart",
  },

  -- 🔊 Sound
  enable_sound = true,
  sound_volume = 3.0,     -- (0.0 - 5.0)
  sound_pack = "default", -- default, mechanical, sci-fi

  -- 🛡️ Smart Exclude
    "TelescopePrompt",
    "NvimTree",
    "neo-tree",
    "lazy",
    "mason",

  excluded_filetypes = { "TelescopePrompt", "NvimTree", "neo-tree", "lazy", "mason" },
  excluded_buftypes = { "nofile", "terminal", "prompt" },
})
```

## 🎮 Commands

- `:SparksToggle` - Toggle plugin
- `:SparksTest` - Test animation effects
- `:checkhealth sparks` - Diagnose configuration

## 🔊 Sound Support

- **macOS**: `afplay`
- **Linux**: `paplay` (PulseAudio), `aplay` (ALSA)
- **Windows**: PowerShell SoundPlayer

## 📄 License

MIT
