# Contributing

Contributions should preserve the small stable interface documented in `:help sparks-interface`.
Behavioral changes need a headless Neovim test through that interface.

## Development

Requirements: Neovim 0.10+, GNU Make, and StyLua. ImageMagick 7 is only needed to
regenerate the demo GIF.

```sh
make test
make lint
make benchmark
```

## Presets

A preset should describe a distinct use case instead of changing only colors. Include its
FPS, duration, particle budget, multiplier, delete behavior, shake behavior, and render
radius. Keep `subtle` usable during a full workday and reserve large budgets for `streamer`.

Open a preset proposal with:

- Name and intended audience.
- Complete Lua configuration.
- A short screen recording or GIF.
- Benchmark output.
- Notes on reduced-motion behavior.

## Effects

Prefer `register_effect()` definitions that use terminal-safe characters. Verify ASCII,
CJK, and emoji rendering. Custom effects must respect `max_particles` and must not invoke
external processes from an update callback.

## Pull Requests

- Add or update tests first for changed public behavior.
- Run `make test`, `make lint`, and `make benchmark`.
- Update `doc/sparks.txt`, README examples, and CHANGELOG when the interface changes.
- Do not add bundled audio without a redistribution-compatible license and attribution.
