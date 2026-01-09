local M = {}
local health = vim.health or require("health")
-- 兼容不同版本的 health report 接口 (nvim 0.10+ vs old)
local start_report = health.start or health.report_start
local report_ok = health.ok or health.report_ok
local report_warn = health.warn or health.report_warn
local report_error = health.error or health.report_error
local report_info = health.info or health.report_info

function M.check()
	start_report("Sparks.nvim check")

	-- 1. 检查配置
	local ok, config_mod = pcall(require, "sparks.config")
	if ok and config_mod.options then
		report_ok("Configuration loaded successfully.")
	else
		report_error("Failed to load configuration.")
	end

	-- 2. 检查声音驱动
	if config_mod and config_mod.options.enable_sound then
		local found_driver = false
		if vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1 then
			if vim.fn.executable("afplay") == 1 then
				report_ok("Sound driver found: afplay (macOS)")
				found_driver = true
			end
		elseif vim.fn.has("unix") == 1 then
			if vim.fn.executable("paplay") == 1 then
				report_ok("Sound driver found: paplay (PulseAudio)")
				found_driver = true
			elseif vim.fn.executable("aplay") == 1 then
				report_ok("Sound driver found: aplay (ALSA)")
				found_driver = true
			end
		elseif vim.fn.has("win32") == 1 then
			report_ok("Sound driver: PowerShell (Windows default)")
			found_driver = true
		end

		if not found_driver then
			report_warn("No supported sound driver found in PATH. Sound effects may not work.")
		end
	else
		report_info("Sound is disabled in configuration.")
	end

	-- 3. 检查 Treesitter (可选依赖)
	if pcall(require, "nvim-treesitter") then
		report_ok("nvim-treesitter found. Smart coloring is active.")
	else
		report_warn("nvim-treesitter not installed. Falling back to default colors.")
	end

	-- 4. 检查性能 (简易)
	local fps = config_mod.options.animation_fps or 30
	if fps < 10 then
		report_warn("FPS setting is low (" .. fps .. "). Animation might look choppy.")
	elseif fps > 60 then
		report_warn("FPS setting is high (" .. fps .. "). This might affect editor performance.")
	else
		report_ok("FPS setting is optimal (" .. fps .. ").")
	end
end

return M
