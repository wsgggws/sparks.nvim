# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sparks.nvim is a Neovim plugin providing satisfying typing effects with a physics-based particle system, combo system, and immersive sound effects. It triggers visual particle animations and sounds when typing characters in insert mode.

## Architecture

The plugin follows a modular architecture with clear separation of concerns:

```
lua/sparks/
├── init.lua        # Main entry point, orchestrating all modules
├── config.lua      # Configuration management with defaults
├── particles.lua   # Physics particle engine (gravity, drag, spawning)
├── window.lua      # Float window management and rendering
├── sound.lua       # Cross-platform sound playback
├── colors.lua      # Smart coloring using Treesitter highlights
└── health.lua      # :checkhealth integration
```

### Data Flow

1. `init.lua` sets up autocmds for `InsertCharPre` and `TextChangedI` events
2. When a character is typed, `trigger_effect()` determines the animation type
3. `particles.spawn()` creates particles with physics properties
4. A `uv.new_timer` runs the animation loop at `animation_fps` intervals
5. `particles.update()` applies gravity/drag to all particles
6. `particles.generate_grid()` converts particles to a 2D grid
7. `window.render_grid()` renders the grid with per-character highlights

### Key Modules

- **config**: Uses `vim.tbl_deep_extend("force", ...)` to merge user opts with defaults
- **particles**: Maintains module-level state (`M.particles`, `M.width`, `M.height`). Each particle has `x`, `y`, `dx`, `dy`, `life`, `char`, `color`
- **window**: Singleton state (`M.state`) managing buf/win handles. Supports adaptive sizing based on `vim.o.columns`
- **sound**: 80ms throttle per sound type using `vim.uv.now()`. Detects OS via `vim.fn.has("mac/win32/linux")`

### Animation Types

Defined in `particles.lua` as character/shape variations: `confetti`, `explode`, `fire`, `matrix`, `snow`, `rain`, `fizz`, `heart`, `sparkle`, plus Easter egg types (`yueyue`, `manman`, `nghuhu`, `shenyiao`).

### Combo System

- Tracks consecutive keystrokes in `state.combo_count`
- Heat modes (`heat_map`) activate at combo thresholds: 10→rainbow, 20→fire
- Every 10th keystroke triggers extra "explode" particles + screen shake

## Commands

- `:SparksToggle` - Toggle plugin on/off
- `:SparksTest` - Run demo animation sequence
- `:checkhealth sparks` - Diagnostic check

## Configuration Highlights

Key user-configurable options (see `config.lua` defaults):
- `triggers`: Map keys to animation types (e.g., `{["{"] = "explode"}`)
- `heat_map`: Combo threshold → mode mapping
- `excluded_filetypes`/`excluded_buftypes`: Smart disable lists
- `sound_pack`: Sound theme (`default`, `mechanical`, `sci-fi`)

## Development Notes

- Animation loop uses `vim.schedule_wrap()` to avoid textlock
- Particles use 1-based coordinates internally; converted to 0-based for nvim_buf_set_extmark
- Window reuse logic checks `nvim_win_is_valid()` + `nvim_buf_is_valid()`
- Colors link to Neovim highlight groups (`String`, `WarningMsg`, etc.)
- macOS sound uses `afplay` with 2.5-3.2x rate for mechanical feel