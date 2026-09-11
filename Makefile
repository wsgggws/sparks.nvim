.PHONY: test lint benchmark demo

NVIM ?= nvim

test:
	$(NVIM) --headless --clean -u tests/minimal_init.lua -l tests/sparks_spec.lua

lint:
	stylua --check lua tests scripts lazyvim-example.lua

benchmark:
	$(NVIM) --headless --clean -u tests/minimal_init.lua -l scripts/benchmark.lua

demo:
	./scripts/demo.sh
