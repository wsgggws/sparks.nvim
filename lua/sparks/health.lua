local M = {}
local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

local function has_sound_driver()
	if vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1 then
		return vim.fn.executable("afplay") == 1 and "afplay" or nil
	end
	if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
		return vim.fn.executable("powershell") == 1 and "PowerShell" or nil
	end
	for _, driver in ipairs({ "paplay", "aplay", "ffplay", "canberra-gtk-play" }) do
		if vim.fn.executable(driver) == 1 then
			return driver
		end
	end
end

function M.check()
	start("sparks.nvim")
	if vim.fn.has("nvim-0.10") == 1 then
		local version = vim.version()
		ok(string.format("Neovim %d.%d.%d is supported", version.major, version.minor, version.patch))
	else
		error("Neovim 0.10 or newer is required")
	end

	local loaded, config = pcall(require, "sparks.config")
	if loaded and config.options then
		ok("Configuration loaded; preset=" .. config.options.preset .. ", render.mode=" .. config.options.render.mode)
	else
		error("Configuration could not be loaded")
		return
	end

	if config.options.enable_sound then
		local driver = has_sound_driver()
		if driver then
			ok("Sound driver found: " .. driver)
		else
			warn("Sound is enabled but no supported player was found")
		end
	else
		info("Sound is disabled (the default)")
	end

	if vim.treesitter.get_captures_at_pos or vim.treesitter.get_captures_at_cursor then
		ok("Treesitter-aware coloring is available")
	else
		warn("Treesitter capture helpers are unavailable; fallback colors will be used")
	end

	local fps = config.options.animation_fps
	local budget = config.options.max_particles
	if fps > 60 or budget > 500 then
		warn(string.format("High render budget: %d FPS, %d particles", fps, budget))
	else
		ok(string.format("Render budget: %d FPS, at most %d particles", fps, budget))
	end
end

return M
