local M = {}

M.presets = {
	subtle = {
		animation_fps = 24,
		default_effect = { "sparkle" },
		duration = 700,
		enable_combo = false,
		enable_shake = false,
		max_particles = 80,
		particle_multiplier = 0.6,
		show_on_delete = false,
		throttle = 80,
		render = { radius = 4 },
	},
	power = {
		animation_fps = 30,
		default_effect = { "confetti", "sparkle", "snow", "rain", "fizz" },
		duration = 1200,
		enable_combo = true,
		enable_shake = true,
		max_particles = 180,
		particle_multiplier = 1,
		show_on_delete = true,
		throttle = 30,
		render = { radius = 6 },
	},
	zen = {
		animation_fps = 20,
		default_effect = { "snow", "fizz" },
		duration = 1600,
		enable_combo = false,
		enable_shake = false,
		max_particles = 60,
		particle_multiplier = 0.5,
		show_on_delete = false,
		throttle = 120,
		render = { radius = 5 },
	},
	streamer = {
		animation_fps = 60,
		default_effect = { "confetti", "sparkle", "fire", "heart" },
		duration = 1400,
		enable_combo = true,
		enable_shake = true,
		max_particles = 400,
		particle_multiplier = 2,
		show_on_delete = true,
		throttle = 16,
		render = { radius = 10 },
	},
}

M.defaults = {
	enabled = true,
	preset = "power",
	position = "right-center",
	duration = 1200,
	throttle = 30,
	border = "none",
	show_on_insert = true,
	show_on_delete = true,
	animation_fps = 30,
	default_effect = { "confetti", "sparkle", "snow", "rain", "fizz" },
	particle_multiplier = 1,
	max_particles = 180,
	render = {
		mode = "fixed",
		radius = 6,
		avoid_completion_menu = true,
		transparent = false,
		show_text = true,
		combo_position = "center",
		safe_radius = { x = 1, y = 0 },
		offset = { x = 2, y = 1 },
	},
	particle_colors = {
		explode = { "SparksString", "SparksNumber", "SparksWarning" },
		confetti = { "SparksString", "SparksNumber", "SparksComment" },
		fire = { "SparksWarning", "SparksError", "SparksConstant" },
		matrix = { "SparksString" },
		snow = { "SparksComment", "SparksString" },
		heart = { "SparksError", "SparksWarning" },
		sparkle = { "SparksWarning", "SparksTitle", "SparksSpecial" },
		rain = { "SparksFunction", "SparksString" },
		fizz = { "SparksType", "SparksNumber" },
		yueyue = { "SparksIdentifier", "SparksError" },
		manman = { "SparksString", "SparksNumber" },
		nghuhu = { "SparksNumber", "SparksTitle" },
		shenyiao = { "SparksSpecial", "SparksWarning" },
	},
	enable_sound = false,
	sound_on_insert = true,
	sound_on_delete = true,
	sound_volume = 1,
	sound_file_insert = nil,
	sound_file_delete = nil,
	sound_pack = "default",
	enable_combo = true,
	combo_threshold = 1,
	combo_timeout = 400,
	heat_map = { [10] = "rainbow", [20] = "fire" },
	enable_shake = true,
	shake_intensity = 1,
	triggers = {
		["{"] = "explode",
		["("] = "confetti",
		["["] = "matrix",
		["!"] = "explode",
		["?"] = "sparkle",
		["*"] = "sparkle",
		["#"] = "matrix",
		["0"] = "matrix",
		["1"] = "matrix",
		["="] = "fizz",
		[";"] = "rain",
		[":"] = "rain",
		["+"] = "fire",
		["^"] = "fire",
		["<"] = "heart",
		["%"] = "confetti",
	},
	ignore_paste = true,
	disable_on_macro = true,
	winblend = 0,
	excluded_filetypes = { "TelescopePrompt", "NvimTree", "neo-tree", "lazy", "mason", "dashboard" },
	excluded_buftypes = { "nofile", "terminal", "prompt" },
	integrations = {
		save = { enabled = false, effect = "sparkle", intensity = 1 },
		diagnostics_clear = { enabled = false, effect = "confetti", intensity = 2 },
		test_success = {
			enabled = false,
			effect = "fire",
			intensity = 3,
			user_events = { "SparksTestSuccess" },
		},
	},
}

M.options = vim.deepcopy(M.defaults)

local replace_keys = {
	default_effect = true,
	excluded_buftypes = true,
	excluded_filetypes = true,
}

local function merge(base, override)
	local result = vim.tbl_deep_extend("force", vim.deepcopy(base), override or {})
	for key in pairs(replace_keys) do
		if override and override[key] ~= nil then
			result[key] = vim.deepcopy(override[key])
		end
	end
	return result
end

local function assert_number(options, key, minimum, maximum)
	local value = options[key]
	if type(value) ~= "number" or value < minimum or (maximum and value > maximum) then
		error(string.format("sparks.nvim: %s must be between %s and %s", key, minimum, maximum or "infinity"), 3)
	end
end

local function assert_list(options, key)
	local value = options[key]
	if type(value) ~= "table" or not vim.islist(value) then
		error("sparks.nvim: " .. key .. " must be a list", 3)
	end
	for _, item in ipairs(value) do
		if type(item) ~= "string" then
			error("sparks.nvim: " .. key .. " must contain strings", 3)
		end
	end
end

local function validate(options)
	if type(options.render) ~= "table" then
		error("sparks.nvim: render must be a table", 3)
	end
	if not vim.tbl_contains({ "cursor", "fixed", "corner" }, options.render.mode) then
		error("sparks.nvim: render.mode must be 'cursor', 'fixed', or the legacy 'corner'", 3)
	end
	if type(options.render.transparent) ~= "boolean" then
		error("sparks.nvim: render.transparent must be a boolean", 3)
	end
	if type(options.render.show_text) ~= "boolean" then
		error("sparks.nvim: render.show_text must be a boolean", 3)
	end
	if not vim.tbl_contains({ "top", "center", "bottom", "none" }, options.render.combo_position) then
		error("sparks.nvim: render.combo_position must be 'top', 'center', 'bottom', or 'none'", 3)
	end
	local safe_radius = options.render.safe_radius
	if
		type(safe_radius) ~= "table"
		or type(safe_radius.x) ~= "number"
		or safe_radius.x < 0
		or safe_radius.x % 1 ~= 0
		or type(safe_radius.y) ~= "number"
		or safe_radius.y < 0
		or safe_radius.y % 1 ~= 0
	then
		error("sparks.nvim: render.safe_radius must contain non-negative integer x and y values", 3)
	end
	local offset = options.render.offset
	if
		type(offset) ~= "table"
		or type(offset.x) ~= "number"
		or offset.x % 1 ~= 0
		or type(offset.y) ~= "number"
		or offset.y % 1 ~= 0
	then
		error("sparks.nvim: render.offset must contain integer x and y values", 3)
	end
	if
		not vim.tbl_contains(
			{ "cursor", "top-left", "top-right", "right-center", "bottom-left", "bottom-right" },
			options.position
		)
	then
		error("sparks.nvim: invalid position '" .. tostring(options.position) .. "'", 3)
	end
	assert_number(options, "animation_fps", 1, 120)
	assert_number(options, "duration", 1)
	assert_number(options, "throttle", 0)
	assert_number(options, "max_particles", 1)
	assert_number(options, "particle_multiplier", 0)
	assert_number(options, "sound_volume", 0, 5)
	assert_number(options, "combo_timeout", 1)
	assert_number(options, "combo_threshold", 1)
	assert_number(options, "shake_intensity", 0)
	assert_number(options, "winblend", 0, 100)
	if type(options.render.radius) ~= "number" or options.render.radius < 1 then
		error("sparks.nvim: render.radius must be at least 1", 3)
	end
	if type(options.default_effect) ~= "string" and type(options.default_effect) ~= "table" then
		error("sparks.nvim: default_effect must be a string or list", 3)
	end
	if type(options.default_effect) == "table" and #options.default_effect == 0 then
		error("sparks.nvim: default_effect list cannot be empty", 3)
	end
	assert_list(options, "excluded_filetypes")
	assert_list(options, "excluded_buftypes")
	if type(options.triggers) ~= "table" then
		error("sparks.nvim: triggers must be a table", 3)
	end
	for key, effect in pairs(options.triggers) do
		if type(key) ~= "string" or type(effect) ~= "string" then
			error("sparks.nvim: triggers must map strings to effect names", 3)
		end
	end
	if type(options.heat_map) ~= "table" then
		error("sparks.nvim: heat_map must be a table", 3)
	end
	for threshold, mode in pairs(options.heat_map) do
		if type(threshold) ~= "number" or type(mode) ~= "string" then
			error("sparks.nvim: heat_map must map numeric thresholds to mode names", 3)
		end
	end
	if type(options.particle_colors) ~= "table" then
		error("sparks.nvim: particle_colors must be a table", 3)
	end
	for effect, palette in pairs(options.particle_colors) do
		if type(palette) ~= "table" or #palette == 0 then
			error("sparks.nvim: particle_colors." .. tostring(effect) .. " must be a non-empty list", 3)
		end
		for _, group in ipairs(palette) do
			if type(group) ~= "string" or group == "" then
				error("sparks.nvim: particle color names must be non-empty strings", 3)
			end
		end
	end
	if type(options.integrations) ~= "table" then
		error("sparks.nvim: integrations must be a table", 3)
	end
	for name, integration in pairs(options.integrations) do
		if type(integration) ~= "table" then
			error("sparks.nvim: integration " .. tostring(name) .. " must be a table", 3)
		end
		if
			integration.enabled and (type(integration.effect) ~= "string" or type(integration.intensity) ~= "number")
		then
			error("sparks.nvim: enabled integrations require an effect and numeric intensity", 3)
		end
	end
	if options.integrations.test_success.enabled then
		local events = options.integrations.test_success.user_events
		if type(events) ~= "table" or not vim.islist(events) or #events == 0 then
			error("sparks.nvim: test_success.user_events must be a non-empty list", 3)
		end
		for _, event in ipairs(events) do
			if type(event) ~= "string" or event == "" then
				error("sparks.nvim: test_success.user_events must contain event names", 3)
			end
		end
	end
end

function M.setup(opts)
	opts = opts or {}
	local preset_name = opts.preset or M.defaults.preset
	local preset = M.presets[preset_name]
	if not preset then
		error("sparks.nvim: unknown preset '" .. tostring(preset_name) .. "'", 2)
	end
	local options = merge(M.defaults, preset)
	options = merge(options, opts)
	if type(options.render) == "table" then
		local render_opts = type(opts.render) == "table" and opts.render or {}
		if render_opts.mode == nil then
			options.render.mode = options.position == "cursor" and "cursor" or "fixed"
		elseif options.render.mode ~= "cursor" and options.position == "cursor" then
			options.position = M.defaults.position
		end
		if render_opts.transparent == nil then
			options.render.transparent = options.render.mode == "cursor"
		end
		if render_opts.show_text == nil then
			options.render.show_text = options.render.mode ~= "cursor"
		end
		if render_opts.combo_position == nil then
			options.render.combo_position = options.render.mode == "cursor" and "top" or "center"
		end
	end
	options.preset = preset_name
	validate(options)
	M.options = options
	return M.options
end

return M
