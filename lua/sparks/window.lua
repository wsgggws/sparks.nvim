local M = {}
local api = vim.api
local namespace = api.nvim_create_namespace("sparks.nvim")
local particle_highlights = {}
local particle_highlight_count = 0

M.state = {
	buf = nil,
	win = nil,
	width = 0,
	height = 0,
	target_win = nil,
	anchor = nil,
	shake_offset = { x = 0, y = 0 },
	target_width = 0,
	target_height = 0,
	placement_signature = nil,
}

local function particle_highlight(group)
	if particle_highlights[group] then
		return particle_highlights[group]
	end
	local ok, hl = pcall(api.nvim_get_hl, 0, { name = group, link = false })
	if not ok or not next(hl) then
		hl = api.nvim_get_hl(0, { name = "SparksString", link = false })
	end
	hl.blend = 0
	particle_highlight_count = particle_highlight_count + 1
	local name = "SparksParticle" .. particle_highlight_count
	api.nvim_set_hl(0, name, hl)
	particle_highlights[group] = name
	return name
end

local function target_dimensions(win)
	return api.nvim_win_get_width(win), api.nvim_win_get_height(win)
end

local function overlay_dimensions(config, win)
	local target_width, target_height = target_dimensions(win)
	local width, height
	if config.render.mode == "cursor" then
		local radius = math.max(2, math.floor(config.render.radius))
		width = radius * 4 + 1
		height = radius * 2 + 1
	elseif target_width < 40 then
		width, height = 16, 8
	elseif target_width < 60 then
		width, height = 20, 10
	else
		width, height = 26, 12
	end
	return math.max(1, math.min(width, target_width)), math.max(1, math.min(height, target_height))
end

local function cursor_anchor(win)
	if win == api.nvim_get_current_win() then
		return { row = vim.fn.winline() - 1, col = vim.fn.wincol() - 1 }
	end
	return { row = 0, col = 0 }
end

local function position(config)
	local row, col
	if config.render.mode == "cursor" then
		local anchor = M.state.anchor or { row = 0, col = 0 }
		row = anchor.row - math.floor(M.state.height / 2) + config.render.offset.y
		col = anchor.col - math.floor(M.state.width / 2) + config.render.offset.x
		return {
			row = row + M.state.shake_offset.y,
			col = col + M.state.shake_offset.x,
		}
	else
		local target_width, target_height = target_dimensions(M.state.target_win)
		local bottom = config.position:find("bottom", 1, true) ~= nil
		local right = config.position:find("right", 1, true) ~= nil
		if config.position == "right-center" then
			row = math.floor((target_height - M.state.height) / 2)
		else
			row = bottom and (target_height - M.state.height) or math.min(2, target_height - M.state.height)
		end
		col = right and (target_width - M.state.width - 1) or 1
		row = row + M.state.shake_offset.y
		col = col + M.state.shake_offset.x
		return {
			row = math.max(0, math.min(row, target_height - M.state.height)),
			col = math.max(0, math.min(col, target_width - M.state.width)),
		}
	end
end

local function close_window()
	if M.state.win and api.nvim_win_is_valid(M.state.win) then
		api.nvim_win_close(M.state.win, true)
	end
	M.state.win = nil
	M.state.buf = nil
end

function M.capture(config)
	local current_win = api.nvim_get_current_win()
	if M.state.win == current_win and M.state.target_win and api.nvim_win_is_valid(M.state.target_win) then
		current_win = M.state.target_win
	end
	M.state.target_win = current_win
	M.state.anchor = cursor_anchor(current_win)
	M.state.target_width, M.state.target_height = target_dimensions(current_win)
	M.state.width, M.state.height = overlay_dimensions(config, current_win)
	return M.state.width, M.state.height
end

function M.create(config)
	if not M.state.target_win or not api.nvim_win_is_valid(M.state.target_win) then
		M.capture(config)
	end
	local width, height = overlay_dimensions(config, M.state.target_win)
	local needs_rebuild = not M.state.win
		or not api.nvim_win_is_valid(M.state.win)
		or not M.state.buf
		or not api.nvim_buf_is_valid(M.state.buf)
	if not needs_rebuild then
		local existing = api.nvim_win_get_config(M.state.win)
		needs_rebuild = existing.win ~= M.state.target_win
	end
	M.state.width, M.state.height = width, height

	if needs_rebuild then
		close_window()
		M.state.buf = api.nvim_create_buf(false, true)
		vim.b[M.state.buf].sparks_overlay = true
		pcall(api.nvim_buf_set_name, M.state.buf, "sparks://overlay")
		api.nvim_set_option_value("bufhidden", "wipe", { buf = M.state.buf })
		api.nvim_set_option_value("buftype", "nofile", { buf = M.state.buf })
		api.nvim_set_option_value("swapfile", false, { buf = M.state.buf })
		api.nvim_set_option_value("modifiable", true, { buf = M.state.buf })
		local pos = position(config)
		M.state.win = api.nvim_open_win(M.state.buf, false, {
			relative = "win",
			win = M.state.target_win,
			width = width,
			height = height,
			row = pos.row,
			col = pos.col,
			style = "minimal",
			border = config.border,
			focusable = false,
			noautocmd = true,
			zindex = config.render.avoid_completion_menu and 40 or 150,
		})
		local background = config.render.transparent and "SparksTransparentFloat" or "SparksFloat"
		api.nvim_set_option_value(
			"winhl",
			"Normal:"
				.. background
				.. ",NormalNC:"
				.. background
				.. ",NormalFloat:"
				.. background
				.. ",FloatBorder:"
				.. background
				.. ",EndOfBuffer:"
				.. background,
			{ win = M.state.win }
		)
	else
		local pos = position(config)
		local signature = table.concat({ M.state.target_win, width, height, pos.row, pos.col }, ":")
		if signature ~= M.state.placement_signature then
			api.nvim_win_set_config(M.state.win, {
				relative = "win",
				win = M.state.target_win,
				width = width,
				height = height,
				row = pos.row,
				col = pos.col,
			})
			M.state.placement_signature = signature
		end
	end
	api.nvim_set_option_value("winblend", config.render.transparent and 100 or config.winblend, { win = M.state.win })
	return width, height
end

function M.cursor_cell(config)
	if config.render.mode ~= "cursor" then
		return math.floor((M.state.width + 1) / 2), math.floor((M.state.height + 1) / 2)
	end
	local anchor = M.state.anchor or { row = 0, col = 0 }
	local pos = position(config)
	return anchor.col - pos.col + 1, anchor.row - pos.row + 1
end

function M.emission_cell()
	return math.floor((M.state.width + 1) / 2), math.floor((M.state.height + 1) / 2)
end

function M.check_and_update(config)
	if not M.state.win or not api.nvim_win_is_valid(M.state.win) then
		return M.create(config)
	end
	if not M.state.target_win or not api.nvim_win_is_valid(M.state.target_win) then
		M.capture(config)
	end
	local current_win = api.nvim_get_current_win()
	if current_win ~= M.state.win and current_win ~= M.state.target_win then
		M.capture(config)
		M.state.placement_signature = nil
	end
	local target_width, target_height = target_dimensions(M.state.target_win)
	if target_width ~= M.state.target_width or target_height ~= M.state.target_height then
		M.state.target_width, M.state.target_height = target_width, target_height
		M.state.placement_signature = nil
	end
	return M.create(config)
end

function M.shake(intensity, config)
	intensity = math.max(0, math.floor(intensity or 0))
	if intensity == 0 then
		M.state.shake_offset = { x = 0, y = 0 }
	else
		M.state.shake_offset = {
			x = math.random(-intensity, intensity),
			y = math.random(-intensity, intensity),
		}
	end
	if M.state.win and api.nvim_win_is_valid(M.state.win) then
		M.create(config or require("sparks.config").options)
	end
end

local function render_row(row, width)
	local chunks, marks = {}, {}
	local display_col, byte_col = 1, 0
	while display_col <= width do
		local cell = row and row[display_col]
		if cell and cell.char and cell.char ~= "" then
			local char = tostring(cell.char)
			local char_width = math.max(1, vim.fn.strdisplaywidth(char))
			if display_col + char_width - 1 <= width then
				table.insert(chunks, char)
				if cell.color then
					table.insert(marks, { start_col = byte_col, end_col = byte_col + #char, color = cell.color })
				end
				byte_col = byte_col + #char
				display_col = display_col + char_width
			else
				table.insert(chunks, " ")
				byte_col = byte_col + 1
				display_col = display_col + 1
			end
		else
			table.insert(chunks, " ")
			byte_col = byte_col + 1
			display_col = display_col + 1
		end
	end
	return table.concat(chunks), marks
end

function M.render_grid(grid)
	if not M.state.win or not api.nvim_win_is_valid(M.state.win) then
		return
	end
	local lines, row_marks = {}, {}
	for y = 1, M.state.height do
		lines[y], row_marks[y] = render_row(grid[y], M.state.width)
	end
	api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)
	api.nvim_buf_clear_namespace(M.state.buf, namespace, 0, -1)
	for y, marks in ipairs(row_marks) do
		for _, mark in ipairs(marks) do
			api.nvim_buf_set_extmark(M.state.buf, namespace, y - 1, mark.start_col, {
				end_col = mark.end_col,
				hl_group = particle_highlight(mark.color),
				strict = false,
			})
		end
	end
end

function M.reset_highlights()
	particle_highlights = {}
	particle_highlight_count = 0
end

function M.close()
	close_window()
	M.state.target_win = nil
	M.state.anchor = nil
	M.state.width = 0
	M.state.height = 0
	M.state.shake_offset = { x = 0, y = 0 }
	M.state.target_width = 0
	M.state.target_height = 0
	M.state.placement_signature = nil
end

function M.is_valid()
	return M.state.win ~= nil and api.nvim_win_is_valid(M.state.win)
end

return M
