local failures = 0
local tests = 0

local function test(name, fn)
	tests = tests + 1
	local ok, err = pcall(fn)
	if ok then
		io.stdout:write("ok " .. tests .. " - " .. name .. "\n")
	else
		failures = failures + 1
		io.stderr:write("not ok " .. tests .. " - " .. name .. "\n" .. tostring(err) .. "\n")
	end
end

local function eq(expected, actual)
	assert(
		vim.deep_equal(expected, actual),
		string.format("expected %s, got %s", vim.inspect(expected), vim.inspect(actual))
	)
end

local function find_sparks_window()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.b[buf].sparks_overlay then
			return win, buf
		end
	end
end

local function overlay_contains(text)
	local _, buf = find_sparks_window()
	if not buf then
		return false
	end
	return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"):find(text, 1, true) ~= nil
end

local function wait_for_overlay()
	assert(
		vim.wait(100, function()
			return find_sparks_window() ~= nil
		end),
		"Sparks did not create an overlay"
	)
	return find_sparks_window()
end

test("emit rejects events while Sparks is disabled", function()
	local sparks = require("sparks")
	sparks.setup({ enabled = false })
	local accepted, reason = sparks.emit({ effect = "confetti" })
	eq(false, accepted)
	eq("disabled", reason)
end)

test("callers can register and emit a custom effect", function()
	local sparks = require("sparks")
	sparks.setup({ enabled = true, enable_sound = false })

	local registered, register_error = sparks.register_effect("test-comet", {
		chars = { "*" },
		count = 1,
		life = { 2, 2 },
	})
	eq(true, registered)
	eq(nil, register_error)

	local accepted = sparks.emit({ effect = "test-comet", text = "T" })
	eq(true, accepted)

	local unknown, reason = sparks.emit({ effect = "does-not-exist" })
	eq(false, unknown)
	eq("unknown_effect", reason)
end)

test("setup accepts the four stable presets and rejects unknown presets", function()
	local sparks = require("sparks")
	for _, preset in ipairs({ "subtle", "power", "zen", "streamer" }) do
		local ok, result = pcall(sparks.setup, { preset = preset, enabled = false })
		eq(true, ok)
		eq(sparks, result)
	end

	local ok, err = pcall(sparks.setup, { preset = "missing" })
	eq(false, ok)
	assert(tostring(err):find("unknown preset", 1, true), tostring(err))
end)

test("position selects fixed or cursor rendering and preserves legacy modes", function()
	local sparks = require("sparks")
	local config = require("sparks.config")
	sparks.setup({ enabled = false })
	eq("right-center", config.options.position)
	eq("fixed", config.options.render.mode)
	eq(false, config.options.render.transparent)
	eq(true, config.options.render.show_text)
	eq("center", config.options.render.combo_position)

	sparks.setup({ enabled = false, position = "cursor" })
	eq("cursor", config.options.position)
	eq("cursor", config.options.render.mode)
	eq(true, config.options.render.transparent)
	eq(false, config.options.render.show_text)
	eq("top", config.options.render.combo_position)
	eq({ x = 1, y = 0 }, config.options.render.safe_radius)
	eq({ x = 2, y = 1 }, config.options.render.offset)

	sparks.setup({ enabled = false, position = "bottom-right" })
	eq("fixed", config.options.render.mode)

	sparks.setup({ enabled = false, position = "top-right", render = { mode = "cursor" } })
	eq("cursor", config.options.render.mode)
	eq(true, config.options.render.transparent)

	sparks.setup({ enabled = false, position = "bottom-right", render = { mode = "corner" } })
	eq("corner", config.options.render.mode)
	eq(false, config.options.render.transparent)
	eq(true, config.options.render.show_text)
	eq("center", config.options.render.combo_position)

	sparks.setup({
		enabled = false,
		render = {
			mode = "cursor",
			transparent = false,
			show_text = true,
			combo_position = "bottom",
			safe_radius = { x = 0, y = 2 },
			offset = { x = -3, y = -1 },
		},
	})
	eq(false, config.options.render.transparent)
	eq(true, config.options.render.show_text)
	eq("bottom", config.options.render.combo_position)
	eq({ x = 0, y = 2 }, config.options.render.safe_radius)
	eq({ x = -3, y = -1 }, config.options.render.offset)

	local ok, err = pcall(sparks.setup, { render = { safe_radius = { x = -1, y = 0 } } })
	eq(false, ok)
	assert(tostring(err):find("safe_radius", 1, true), tostring(err))
	local offset_ok, offset_err = pcall(sparks.setup, { render = { offset = { x = 0.5, y = 0 } } })
	eq(false, offset_ok)
	assert(tostring(offset_err):find("offset", 1, true), tostring(offset_err))
end)

test("fixed rendering supports right top, center, and bottom placement", function()
	local sparks = require("sparks")
	local target = vim.api.nvim_get_current_win()
	local target_width = vim.api.nvim_win_get_width(target)
	local target_height = vim.api.nvim_win_get_height(target)
	for _, case in ipairs({
		{
			position = "top-right",
			row = function()
				return 2
			end,
		},
		{
			position = "right-center",
			row = function(height)
				return math.floor((target_height - height) / 2)
			end,
		},
		{
			position = "bottom-right",
			row = function(height)
				return target_height - height
			end,
		},
	}) do
		sparks.setup({
			enabled = true,
			enable_combo = false,
			enable_sound = false,
			position = case.position,
			throttle = 0,
		})
		eq(true, sparks.emit({ effect = "sparkle", throttle = false }))
		local win = wait_for_overlay()
		local overlay = vim.api.nvim_win_get_config(win)
		eq(case.row(overlay.height), overlay.row)
		eq(target_width - overlay.width - 1, overlay.col)
	end
end)

test("v1 rejects unknown configured effects during setup", function()
	local sparks = require("sparks")
	eq("1.0.0", sparks.version)
	sparks.setup({ enabled = true, default_effect = "sparkle", enable_sound = false })
	local ok, err = pcall(sparks.setup, { default_effect = "missing" })
	eq(false, ok)
	assert(tostring(err):find("unknown default effect", 1, true), tostring(err))
	eq(true, sparks.emit({ force = true, throttle = false }))
end)

test("register_effect rejects malformed definitions", function()
	local sparks = require("sparks")
	local ok, err = sparks.register_effect("empty", { chars = {} })
	eq(false, ok)
	assert(tostring(err):find("chars", 1, true), tostring(err))
end)

test("cursor rendering stays near the cursor and preserves Unicode display width", function()
	local sparks = require("sparks")
	sparks.setup({
		enabled = true,
		enable_combo = false,
		enable_sound = false,
		position = "cursor",
		throttle = 0,
		render = { radius = 4 },
	})
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "界👩‍💻" })
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
	eq(true, sparks.emit({ effect = "heart", text = "界👩‍💻" }))
	vim.wait(100, function()
		local win, buf = find_sparks_window()
		if not win then
			return false
		end
		local config = vim.api.nvim_win_get_config(win)
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		return #lines == config.height and vim.fn.strdisplaywidth(lines[1] or "") == config.width
	end)

	local win, buf = find_sparks_window()
	assert(win, "Sparks did not create an overlay")
	local config = vim.api.nvim_win_get_config(win)
	eq(-3, config.row)
	eq(-6, config.col)
	for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
		eq(config.width, vim.fn.strdisplaywidth(line))
	end
	assert(not overlay_contains("界👩‍💻"), "cursor mode rendered input text over buffer content")
end)

test("cursor overlays keep empty cells transparent and particle cells opaque", function()
	local sparks = require("sparks")
	sparks.setup({
		enabled = true,
		enable_combo = false,
		enable_sound = false,
		position = "cursor",
		throttle = 0,
		render = { radius = 4 },
	})
	eq(true, sparks.emit({ effect = "sparkle", throttle = false }))
	local win = wait_for_overlay()
	eq(100, vim.api.nvim_get_option_value("winblend", { win = win }))
	eq(100, vim.api.nvim_get_hl(0, { name = "SparksTransparentFloat", link = false }).blend)
	eq(0, vim.api.nvim_get_hl(0, { name = "SparksString", link = false }).blend)

	local _, buf = find_sparks_window()
	local marks
	assert(
		vim.wait(100, function()
			marks = vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })
			return #marks > 0
		end),
		"particle render did not create highlight marks"
	)
	local particle_hl = marks[1][4].hl_group
	assert(type(particle_hl) == "string", vim.inspect(particle_hl))
	eq(0, vim.api.nvim_get_hl(0, { name = particle_hl, link = false }).blend)

	sparks.setup({
		enabled = true,
		enable_combo = false,
		enable_sound = false,
		position = "cursor",
		throttle = 0,
		winblend = 23,
		render = { transparent = false },
	})
	eq(true, sparks.emit({ effect = "sparkle", throttle = false }))
	local opaque_win = wait_for_overlay()
	eq(23, vim.api.nvim_get_option_value("winblend", { win = opaque_win }))
end)

test("cursor overlays hide input text, move combos, and protect the cursor line", function()
	local sparks = require("sparks")
	local particles = require("sparks.particles")
	local registered, err = sparks.register_effect("safe-zone-probe", function(particle)
		particle.char = "S"
		particle.dx = 0
		particle.dy = 0
		particle.life = 20
	end)
	eq(true, registered)
	eq(nil, err)
	sparks.setup({
		enabled = true,
		enable_combo = true,
		combo_threshold = 1,
		enable_sound = false,
		position = "cursor",
		throttle = 0,
		render = { radius = 4 },
	})
	eq(true, sparks.emit({ effect = "safe-zone-probe", kind = "insert", text = "INPUT", throttle = false }))
	local _, buf = wait_for_overlay()
	assert(
		vim.wait(100, function()
			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			return (lines[1] or ""):find("x1", 1, true) ~= nil
		end),
		"cursor combo was not rendered at the top"
	)
	assert(not overlay_contains("INPUT"), "cursor mode rendered input text over buffer content")
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local config = require("sparks.config")
	local window = require("sparks.window")
	local center_y = math.floor((particles.height + 1) / 2)
	local center_x = math.floor((particles.width + 1) / 2)
	local cursor_x, cursor_y = window.cursor_cell(config.options)
	eq(center_x - 2, cursor_x)
	eq(center_y - 1, cursor_y)
	eq("   ", lines[cursor_y]:sub(cursor_x - 1, cursor_x + 1))
	eq("S", lines[center_y]:sub(center_x, center_x))

	sparks.setup({
		enabled = true,
		enable_combo = true,
		combo_threshold = 1,
		enable_sound = false,
		position = "cursor",
		throttle = 0,
		render = { combo_position = "none" },
	})
	eq(true, sparks.emit({ effect = "sparkle", kind = "insert", text = "HIDDEN", throttle = false }))
	wait_for_overlay()
	assert(not overlay_contains("x1"), "disabled combo label was rendered")
	assert(not overlay_contains("HIDDEN"), "disabled cursor text was rendered")
end)

test("corner overlays preserve configured opacity and centered text", function()
	local sparks = require("sparks")
	sparks.setup({
		enabled = true,
		enable_combo = false,
		enable_sound = false,
		throttle = 0,
		winblend = 37,
		render = { mode = "corner" },
	})
	eq(true, sparks.emit({ effect = "sparkle", text = "CORNER", throttle = false }))
	local win = wait_for_overlay()
	eq(37, vim.api.nvim_get_option_value("winblend", { win = win }))
	assert(
		vim.wait(100, function()
			return overlay_contains("CORNER")
		end),
		"corner mode stopped rendering event text"
	)
end)

test("corner rendering follows the active split and uses the true bottom edge", function()
	local sparks = require("sparks")
	sparks.setup({
		enabled = true,
		enable_combo = false,
		enable_sound = false,
		throttle = 0,
		render = { mode = "corner" },
		position = "bottom-right",
	})
	vim.cmd("vnew")
	local target = vim.api.nvim_get_current_win()
	local target_width = vim.api.nvim_win_get_width(target)
	local target_height = vim.api.nvim_win_get_height(target)
	eq(true, sparks.emit({ effect = "sparkle", throttle = false }))
	assert(
		vim.wait(100, function()
			local win = find_sparks_window()
			return win and vim.api.nvim_win_get_config(win).win == target
		end),
		"overlay did not follow the active split"
	)
	local win = find_sparks_window()
	local overlay = vim.api.nvim_win_get_config(win)
	eq(target_height - overlay.height, overlay.row)
	eq(target_width - overlay.width - 1, overlay.col)
	vim.cmd("wincmd p")
	local next_target = vim.api.nvim_get_current_win()
	assert(
		vim.wait(100, function()
			local moved = find_sparks_window()
			return moved and vim.api.nvim_win_get_config(moved).win == next_target
		end),
		"active overlay did not migrate after switching splits"
	)
	vim.api.nvim_win_close(target, true)
end)

test("combo restarts after its timeout", function()
	local sparks = require("sparks")
	sparks.setup({
		enabled = true,
		enable_combo = true,
		combo_threshold = 1,
		combo_timeout = 20,
		enable_sound = false,
		throttle = 0,
	})
	sparks.emit({ effect = "sparkle", kind = "insert", text = "A", throttle = false })
	sparks.emit({ effect = "sparkle", kind = "insert", text = "B", throttle = false })
	assert(
		vim.wait(100, function()
			return overlay_contains("x2")
		end),
		"combo did not reach x2"
	)
	vim.wait(30)
	sparks.emit({ effect = "sparkle", kind = "insert", text = "C", throttle = false })
	assert(
		vim.wait(100, function()
			return overlay_contains("x1")
		end),
		"combo did not restart at x1"
	)
end)

test("SparksToggle controls subsequent emissions", function()
	local sparks = require("sparks")
	sparks.setup({ enabled = true, enable_sound = false })
	vim.cmd("SparksToggle")
	local accepted, reason = sparks.emit({ effect = "sparkle", force = true, throttle = false })
	eq(false, accepted)
	eq("disabled", reason)
	vim.cmd("SparksToggle")
	eq(true, sparks.emit({ effect = "sparkle", force = true, throttle = false }))
end)

test("save integration emits feedback", function()
	local sparks = require("sparks")
	sparks.setup({
		enabled = true,
		enable_sound = false,
		integrations = { save = { enabled = true, effect = "sparkle" } },
	})
	vim.api.nvim_exec_autocmds("BufWritePost", { buffer = 0 })
	assert(
		vim.wait(100, function()
			return find_sparks_window() ~= nil
		end),
		"save did not create feedback"
	)
end)

test("clearing diagnostics emits feedback", function()
	local sparks = require("sparks")
	sparks.setup({
		enabled = true,
		enable_sound = false,
		integrations = { diagnostics_clear = { enabled = true, effect = "confetti" } },
	})
	local namespace = vim.api.nvim_create_namespace("sparks-test-diagnostics")
	vim.diagnostic.set(
		namespace,
		0,
		{ { lnum = 0, col = 0, message = "error", severity = vim.diagnostic.severity.ERROR } }
	)
	vim.wait(50)
	vim.diagnostic.reset(namespace, 0)
	assert(
		vim.wait(150, function()
			return find_sparks_window() ~= nil
		end),
		"diagnostics clear did not create feedback"
	)
end)

test("test-success integration and preview command emit feedback", function()
	local sparks = require("sparks")
	sparks.setup({
		enabled = true,
		enable_sound = false,
		integrations = {
			test_success = { enabled = true, effect = "fire", user_events = { "SparksSpecPassed" } },
		},
	})
	vim.api.nvim_exec_autocmds("User", { pattern = "SparksSpecPassed" })
	assert(
		vim.wait(100, function()
			return find_sparks_window() ~= nil
		end),
		"test-success event did not create feedback"
	)
	vim.cmd("SparksPreview")
	assert(
		vim.wait(100, function()
			return find_sparks_window() ~= nil
		end),
		"preview did not create feedback"
	)
end)

if failures > 0 then
	error(string.format("%d of %d tests failed", failures, tests))
end

io.stdout:write(string.format("1..%d\n", tests))
