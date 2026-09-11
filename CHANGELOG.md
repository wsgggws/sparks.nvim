# Changelog

All notable changes follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
The stable public interface follows semantic versioning from 1.0.0 onward.

## [1.0.0] - 2026-09-09

### Added

- A documented and tested stable interface: `setup`, `emit`, `register_effect`,
  `enable`, `disable`, `toggle`, and `version`.
- Neovim 0.10, stable, and nightly CI coverage.
- Public-interface performance benchmark and reproducible demo GIF generator.
- Complete `:help sparks`, English documentation, release notes, and contribution guide.

### Fixed

- Cursor overlays no longer hide code behind an opaque rectangular background.
- Cursor particles retain full color opacity, while inserted text is hidden by
  default and a configurable safe area protects the active cursor row.
- Combo labels can be placed at the top, center, or bottom of the overlay, or hidden.
- Cursor-mode visuals default to a configurable two-column, one-row offset from the cursor.
- Placement now uses one `position` option and defaults to `right-center`; cursor following
  and fixed `top-right` or `bottom-right` placement remain available.

## [0.4.0] - 2026-09-09

### Added

- Public event emission and custom effect registration.
- Optional save, diagnostics-cleared, and test-success event integrations.

## [0.3.0] - 2026-09-09

### Added

- Cursor-local rendering and retained corner rendering.
- `subtle`, `power`, `zen`, and `streamer` presets.
- `:SparksPreview` effect showcase.

## [0.2.0] - 2026-09-09

### Fixed

- Toggle behavior, combo timeout, multi-window placement, adaptive sizing, and
  bottom-corner calculation.
- Unicode display width and extmark byte offsets.
- Shell-safe asynchronous sound playback and sound-disabled default.

### Added

- Headless behavior tests, CI, health checks, particle budgets, and help documentation.

## [0.1.4] - 2026-02-05

- Added the original video demo.
