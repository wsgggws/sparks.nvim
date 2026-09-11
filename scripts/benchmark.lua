local sparks = require("sparks")
local uv = vim.uv or vim.loop

vim.api.nvim_buf_set_lines(0, 0, -1, false, {
	"local function benchmark()",
	"  return 'sparks.nvim'",
	"end",
})
vim.api.nvim_win_set_cursor(0, { 2, 9 })

sparks.setup({
	preset = "power",
	enable_combo = false,
	enable_sound = false,
	position = "cursor",
})

collectgarbage("collect")
local before_kib = collectgarbage("count")
local started = uv.hrtime()
local events = 1000
local accepted = 0

for index = 1, events do
	local ok = sparks.emit({
		effect = index % 2 == 0 and "sparkle" or "confetti",
		force = true,
		throttle = false,
	})
	if ok then
		accepted = accepted + 1
	end
end

local elapsed_ms = (uv.hrtime() - started) / 1e6
local after_kib = collectgarbage("count")
sparks.disable()

assert(accepted == events, string.format("accepted %d of %d events", accepted, events))
local uname = uv.os_uname()
local version = vim.version()
io.stdout:write("scope: emit_admission_and_particle_budget\n")
io.stdout:write(string.format("neovim: %d.%d.%d\n", version.major, version.minor, version.patch))
io.stdout:write(string.format("platform: %s %s\n", uname.sysname, uname.machine))
io.stdout:write(string.format("events: %d\n", events))
io.stdout:write(string.format("elapsed_ms: %.2f\n", elapsed_ms))
io.stdout:write(string.format("events_per_second: %.0f\n", events / (elapsed_ms / 1000)))
io.stdout:write(string.format("lua_memory_delta_kib: %.1f\n", after_kib - before_kib))

local maximum_ms = tonumber(os.getenv("SPARKS_BENCH_MAX_MS") or "0")
if maximum_ms > 0 then
	assert(elapsed_ms <= maximum_ms, string.format("benchmark exceeded %.2fms budget", maximum_ms))
end
