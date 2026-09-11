# sparks.nvim development

Sparks is a Neovim 0.10+ visual-feedback plugin. Treat `setup()`, `emit()`,
`register_effect()`, `enable()`, `disable()`, `toggle()`, commands, and the options listed
in `doc/sparks.txt` as the stable v1 interface.

## Workflow

1. Read `doc/sparks.txt` when changing behavior or configuration.
2. Add a failing test in `tests/sparks_spec.lua` through the stable interface.
3. Implement one behavior slice and run `make test` until it passes.
4. Run `make lint` and `make benchmark` before finishing.
5. Update help, README, and CHANGELOG together when observable behavior changes.

## Design constraints

- Keep orchestration behind the interface in `lua/sparks/init.lua`; integrations call
  `emit()` instead of reaching into window or particle state.
- Keep rendering in `lua/sparks/window.lua` Unicode-safe: grid positions are display cells,
  while extmark positions are UTF-8 byte offsets.
- Keep the input and frame loops bounded. New effects respect `max_particles` and perform no
  external I/O during updates.
- Launch sound players with `vim.system()` argument arrays. User paths never pass through a
  shell command string.
- Register new built-in effects in the registry and verify them through `SparksPreview`.

Generate the repository demo only when its visible behavior changes: `make demo` requires
ImageMagick 7 and writes `assets/demo.gif`.
