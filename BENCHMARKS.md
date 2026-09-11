# Performance baseline

The benchmark exercises the stable public interface. It submits 1,000 unthrottled cursor-mode
events with the `power` preset, sound and combo disabled, and the default 180-particle budget.
It measures event admission, cursor capture, color lookup, effect creation, and bounded-particle
management. It does not claim to measure terminal drawing latency.

Baseline recorded on 2026-09-09:

| Environment | Runs | Median time | Median throughput | Median Lua memory delta |
| --- | ---: | ---: | ---: | ---: |
| Neovim 0.12.5, macOS arm64 | 5 | 5.90 ms | 169,405 events/s | 589.6 KiB |

Raw elapsed times were 7.96, 5.90, 6.01, 5.48, and 5.64 ms. Results vary by CPU, Neovim
build, allocator state, parsers, and active configuration. Compare changes on the same machine:

```sh
make benchmark
```

For a stable CI runner, set a local regression ceiling:

```sh
SPARKS_BENCH_MAX_MS=20 make benchmark
```

Functional compatibility is tested separately on Neovim 0.10.4, stable, and nightly. Nightly
is informative; the minimum and stable jobs are required.
