local M = {}
M.version = "1.0.0"

local api = vim.api
local config = require("sparks.config")
local particles = require("sparks.particles")
local sound = require("sparks.sound")
local window = require("sparks.window")
local uv = vim.uv or vim.loop

local state = {
	timer = nil,
	last_trigger = 0,
	last_activity = 0,
	combo_count = 0,
	active_text = nil,
	diagnostic_errors = {},
}

local function close_timer()
	if state.timer then
		state.timer:stop()
		if not state.timer:is_closing() then
			state.timer:close()
		end
		state.timer = nil
	end
end

local function reset_runtime()
	close_timer()
	window.close()
	particles.clear()
	state.last_trigger = 0
	state.last_activity = 0
	state.combo_count = 0
	state.active_text = nil
	state.diagnostic_errors = {}
end

local function effect_from_default()
	local value = config.options.default_effect
	if type(value) == "table" then
		return value[math.random(#value)]
	end
	return value
end

local function is_excluded()
	local options = config.options
	return vim.tbl_contains(options.excluded_filetypes, vim.bo.filetype)
		or vim.tbl_contains(options.excluded_buftypes, vim.bo.buftype)
		or (options.ignore_paste and vim.o.paste)
		or (options.disable_on_macro and (vim.fn.reg_recording() ~= "" or vim.fn.reg_executing() ~= ""))
end

local function current_heat_mode()
	local selected_threshold, selected_mode = -1, nil
	for threshold, mode in pairs(config.options.heat_map or {}) do
		if state.combo_count >= threshold and threshold > selected_threshold then
			selected_threshold, selected_mode = threshold, mode
		end
	end
	return selected_mode
end

local function combo_visible()
	return state.active_text
		and config.options.enable_combo
		and config.options.render.combo_position ~= "none"
		and state.combo_count >= config.options.combo_threshold
end

local function has_overlay_text()
	return state.active_text and (config.options.render.show_text or combo_visible())
end

local function protect_cursor(grid)
	if config.options.render.mode ~= "cursor" then
		return
	end
	local center_x, center_y = window.cursor_cell(config.options)
	local safe_radius = config.options.render.safe_radius
	local minimum_x = center_x - safe_radius.x
	local maximum_x = center_x + safe_radius.x
	for y = math.max(1, center_y - safe_radius.y), math.min(particles.height, center_y + safe_radius.y) do
		for x, cell in pairs(grid[y]) do
			local width = math.max(1, vim.fn.strdisplaywidth(cell.char or ""))
			if x <= maximum_x and x + width - 1 >= minimum_x then
				grid[y][x] = nil
			end
		end
	end
end

local function render_text_parts(grid, parts, y)
	local total_width = 0
	for index, part in ipairs(parts) do
		total_width = total_width + vim.fn.strdisplaywidth(part.text)
		if index < #parts then
			total_width = total_width + 1
		end
	end
	local x = math.max(1, math.floor((particles.width - total_width) / 2) + 1)
	for _, part in ipairs(parts) do
		grid[y][x] = { char = part.text, color = part.color }
		x = x + math.max(1, vim.fn.strdisplaywidth(part.text)) + 1
	end
end

local function overlay_text(grid)
	local render = config.options.render
	local center_y = math.floor((particles.height + 1) / 2)
	local show_combo = combo_visible()
	if render.show_text and state.active_text then
		local parts = { { text = state.active_text, color = "SparksString" } }
		if show_combo and render.combo_position == "center" then
			table.insert(parts, { text = "x" .. state.combo_count, color = "SparksWarning" })
		end
		render_text_parts(grid, parts, center_y)
	end
	if show_combo and (not render.show_text or render.combo_position ~= "center") then
		local rows = { top = 1, center = center_y, bottom = particles.height }
		render_text_parts(
			grid,
			{ { text = "x" .. state.combo_count, color = "SparksWarning" } },
			rows[render.combo_position]
		)
	end
end

local function start_animation()
	if state.timer then
		return
	end
	local width, height = window.create(config.options)
	particles.resize(width, height)
	state.timer = uv.new_timer()
	state.timer:start(
		0,
		math.max(1, math.floor(1000 / config.options.animation_fps)),
		vim.schedule_wrap(function()
			if not config.options.enabled then
				reset_runtime()
				return
			end
			local new_width, new_height = window.check_and_update(config.options)
			particles.resize(new_width, new_height)
			local has_particles = particles.update()
			if state.active_text and uv.now() - state.last_activity > config.options.combo_timeout then
				state.active_text = nil
				state.combo_count = 0
			end
			if not has_particles and not has_overlay_text() then
				close_timer()
				window.close()
				return
			end
			local grid = particles.generate_grid()
			protect_cursor(grid)
			overlay_text(grid)
			window.render_grid(grid)
		end)
	)
end

local function normalize_event(event)
	if type(event) == "string" then
		return { effect = event }
	end
	return vim.deepcopy(event or {})
end

function M.emit(event)
	event = normalize_event(event)
	if not config.options.enabled then
		return false, "disabled"
	end
	local effect = event.effect or effect_from_default()
	if not particles.has_effect(effect) then
		return false, "unknown_effect"
	end
	if is_excluded() and not event.force then
		return false, "excluded"
	end
	local now = uv.now()
	if event.throttle ~= false and now - state.last_trigger < config.options.throttle then
		return false, "throttled"
	end
	local width, height = window.capture(config.options)
	particles.resize(width, height)
	state.last_trigger = now
	local kind = event.kind or "event"
	if kind == "insert" then
		if now - state.last_activity > config.options.combo_timeout then
			state.combo_count = 0
		end
		state.combo_count = state.combo_count + 1
		state.active_text = event.text
	elseif kind == "delete" then
		state.combo_count = 0
		state.active_text = nil
	elseif event.text then
		state.active_text = event.text
	end
	state.last_activity = now

	local intensity = math.max(0, tonumber(event.intensity) or 1)
	local count =
		math.max(0, math.floor(particles.default_count(effect) * config.options.particle_multiplier * intensity))
	local center_x, center_y = window.emission_cell()
	if count > 0 then
		particles.spawn(center_x, center_y, count, effect, event.text or "*", current_heat_mode())
	end

	if kind == "insert" and state.combo_count > 0 and state.combo_count % 10 == 0 then
		particles.spawn(center_x, center_y, math.floor(10 * intensity), "explode", "*", current_heat_mode())
		if config.options.enable_shake then
			window.shake(config.options.shake_intensity, config.options)
			vim.defer_fn(function()
				window.shake(0, config.options)
			end, 50)
		end
	elseif kind == "delete" and config.options.enable_shake then
		window.shake(1, config.options)
		vim.defer_fn(function()
			window.shake(0, config.options)
		end, 50)
	end

	if kind == "insert" or kind == "delete" then
		sound.play(kind, config.options)
	end
	vim.schedule(start_animation)
	return true
end

function M.register_effect(name, definition)
	return particles.register_effect(name, definition)
end

function M.enable()
	config.options.enabled = true
	return true
end

function M.disable()
	config.options.enabled = false
	reset_runtime()
	return false
end

function M.toggle()
	if config.options.enabled then
		return M.disable()
	end
	return M.enable()
end

local function create_highlights()
	api.nvim_set_hl(0, "SparksFloat", { bg = "NONE", fg = "NONE" })
	local normal = api.nvim_get_hl(0, { name = "Normal", link = false })
	api.nvim_set_hl(0, "SparksTransparentFloat", { bg = "NONE", fg = normal.fg or 0xffffff, blend = 100 })
	local links = {
		SparksComment = "Comment",
		SparksConstant = "Constant",
		SparksError = "Error",
		SparksFunction = "Function",
		SparksIdentifier = "Identifier",
		SparksNumber = "Number",
		SparksSpecial = "Special",
		SparksString = "String",
		SparksTitle = "Title",
		SparksType = "Type",
		SparksWarning = "WarningMsg",
	}
	for name, base in pairs(links) do
		local hl = api.nvim_get_hl(0, { name = base, link = false })
		api.nvim_set_hl(0, name, { fg = hl.fg, bg = "NONE", bold = hl.bold, italic = hl.italic, blend = 0 })
	end
	window.reset_highlights()
end

local function setup_input_events(group)
	if config.options.show_on_insert then
		api.nvim_create_autocmd("InsertCharPre", {
			group = group,
			callback = function()
				local effect = config.options.triggers[vim.v.char]
				M.emit({ effect = effect, kind = "insert", text = vim.v.char })
			end,
		})
	end
	if config.options.show_on_delete then
		local previous = {}
		local function snapshot()
			local cursor = api.nvim_win_get_cursor(0)
			previous = {
				changedtick = vim.b.changedtick,
				line_count = api.nvim_buf_line_count(0),
				line = api.nvim_get_current_line(),
				row = cursor[1],
			}
		end
		api.nvim_create_autocmd({ "InsertEnter", "InsertCharPre" }, { group = group, callback = snapshot })
		api.nvim_create_autocmd("CursorMovedI", {
			group = group,
			callback = function()
				if previous.changedtick == vim.b.changedtick then
					snapshot()
				end
			end,
		})
		api.nvim_create_autocmd("TextChangedI", {
			group = group,
			callback = function()
				local line_count = api.nvim_buf_line_count(0)
				local cursor = api.nvim_win_get_cursor(0)
				local line = api.nvim_get_current_line()
				local deleted = previous.changedtick
					and vim.b.changedtick ~= previous.changedtick
					and (line_count < previous.line_count or (cursor[1] == previous.row and #line < #previous.line))
				if deleted then
					M.emit({ effect = "explode", kind = "delete", text = "X" })
				end
				snapshot()
			end,
		})
	end
	api.nvim_create_autocmd("InsertLeave", {
		group = group,
		callback = function()
			state.active_text = nil
			state.combo_count = 0
		end,
	})
end

local function count_errors(buf)
	local severity = vim.diagnostic.severity.ERROR
	return #vim.diagnostic.get(buf, { severity = severity })
end

local function setup_integrations(group)
	local integrations = config.options.integrations
	if integrations.save.enabled then
		api.nvim_create_autocmd("BufWritePost", {
			group = group,
			callback = function()
				M.emit({ effect = integrations.save.effect, intensity = integrations.save.intensity, force = true })
			end,
		})
	end
	if integrations.diagnostics_clear.enabled then
		api.nvim_create_autocmd("DiagnosticChanged", {
			group = group,
			callback = function(args)
				local before = state.diagnostic_errors[args.buf] or 0
				local after = count_errors(args.buf)
				state.diagnostic_errors[args.buf] = after
				if before > 0 and after == 0 then
					M.emit({
						effect = integrations.diagnostics_clear.effect,
						intensity = integrations.diagnostics_clear.intensity,
						force = true,
					})
				end
			end,
		})
	end
	if integrations.test_success.enabled then
		for _, pattern in ipairs(integrations.test_success.user_events) do
			api.nvim_create_autocmd("User", {
				group = group,
				pattern = pattern,
				callback = function()
					M.emit({
						effect = integrations.test_success.effect,
						intensity = integrations.test_success.intensity,
						force = true,
					})
				end,
			})
		end
	end
end

local function preview()
	local effects = particles.effect_names()
	for index, effect in ipairs(effects) do
		vim.defer_fn(function()
			M.emit({ effect = effect, text = effect, intensity = 1.5, force = true, throttle = false })
		end, (index - 1) * 450)
	end
end

function M.setup(options)
	local previous_options = config.options
	config.setup(options)
	local validation_error
	local configured_effects = type(config.options.default_effect) == "table" and config.options.default_effect
		or { config.options.default_effect }
	for _, effect in ipairs(configured_effects) do
		if not particles.has_effect(effect) then
			validation_error = "sparks.nvim: unknown default effect '" .. tostring(effect) .. "'"
			break
		end
	end
	if not validation_error then
		for key, effect in pairs(config.options.triggers) do
			if not particles.has_effect(effect) then
				validation_error = string.format("sparks.nvim: trigger %q uses unknown effect %q", key, effect)
				break
			end
		end
	end
	if not validation_error then
		for name, integration in pairs(config.options.integrations) do
			if integration.enabled and not particles.has_effect(integration.effect) then
				validation_error =
					string.format("sparks.nvim: integration %q uses unknown effect %q", name, integration.effect)
				break
			end
		end
	end
	if validation_error then
		config.options = previous_options
		error(validation_error, 2)
	end
	reset_runtime()
	create_highlights()
	local group = api.nvim_create_augroup("Sparks", { clear = true })
	api.nvim_create_autocmd("ColorScheme", { group = group, callback = create_highlights })
	setup_input_events(group)
	setup_integrations(group)
	api.nvim_create_user_command("SparksToggle", function()
		vim.notify("Sparks: " .. (M.toggle() and "enabled" or "disabled"))
	end, { force = true })
	api.nvim_create_user_command("SparksTest", preview, { force = true })
	api.nvim_create_user_command("SparksPreview", preview, { force = true })
	return M
end

return M
