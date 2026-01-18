local M = {}
local api = vim.api

-- 根据当前窗口大小计算尺寸（相对于窗口定位时使用）
local function calculate_window_size(win)
	local win_config = api.nvim_win_get_config(win)
	local win_width = win_config.width

	local width, height, offset

	if win_width < 40 then
		width, height = 16, 8
		offset = 1
	elseif win_width < 60 then
		width, height = 20, 10
		offset = 2
	else
		width, height = 26, 12
		offset = 3
	end

	return width, height, offset
end

-- 计算窗口位置（基于当前窗口）
local function get_window_position(config_pos, width, height, win)
	local win_config = api.nvim_win_get_config(win)
	local win_width = win_config.width
	local _, _, offset = calculate_window_size(win)

	-- relative="win" 时，row/col 是相对于目标窗口的
	-- top-right: 靠右边缘 = 窗口宽度 - 动画宽度 - offset
	-- top-left: 靠左边缘 = 0
	local positions = {
		["top-right"] = { row = 0, col = win_width - width - offset },
		["top-left"] = { row = 0, col = 0 },
		["bottom-right"] = { row = height + 1, col = win_width - width - offset },
		["bottom-left"] = { row = height + 1, col = 0 },
	}
	return positions[config_pos] or positions["top-right"]
end

M.state = {
	buf = nil,
	win = nil,
	width = 20,
	height = 10,
	shake_offset = nil,
	target_win = nil, -- 记录动画窗口所属的编辑器窗口
}

function M.shake(intensity)
	if not M.state.win or not api.nvim_win_is_valid(M.state.win) then
		return
	end

	M.state.shake_offset = {
		x = math.random(-intensity, intensity),
		y = math.random(-intensity, intensity),
	}

	-- 立即应用配置
	local config_pos = require("sparks.config").options.position
	local pos = get_window_position(config_pos, M.state.width, M.state.height, M.state.target_win)

	local new_opts = {
		relative = "win",
		win = M.state.target_win,
		row = pos.row + M.state.shake_offset.y,
		col = pos.col + M.state.shake_offset.x,
	}
	api.nvim_win_set_config(M.state.win, new_opts)
end

function M.create(config)
	-- 获取当前编辑器窗口（动画窗口将相对于此窗口定位）
	local current_win = api.nvim_get_current_win()

	-- 自适应计算窗口大小
	local width, height, _ = calculate_window_size(current_win)
	M.state.width = width
	M.state.height = height
	M.state.target_win = current_win

	-- 复用窗口逻辑：检查当前窗口是否仍然有效
	if M.state.win and api.nvim_win_is_valid(M.state.win) then
		-- 如果目标窗口变了，需要重建
		if M.state.target_win ~= current_win then
			api.nvim_win_close(M.state.win, true)
			M.state.win = nil
			M.state.buf = nil
		elseif M.state.buf and api.nvim_buf_is_valid(M.state.buf) then
			return
		end
	end

	-- 创建新 Buffer
	M.state.buf = api.nvim_create_buf(false, true)
	api.nvim_set_option_value("bufhidden", "wipe", { buf = M.state.buf })
	api.nvim_set_option_value("buftype", "nofile", { buf = M.state.buf })
	api.nvim_set_option_value("swapfile", false, { buf = M.state.buf })

	-- 初始化为空
	local empty_lines = {}
	for _ = 1, M.state.height do
		table.insert(empty_lines, "")
	end
	api.nvim_buf_set_lines(M.state.buf, 0, -1, false, empty_lines)

	local pos = get_window_position(config.position, M.state.width, M.state.height, M.state.target_win)

	-- 震动偏移应用
	if M.state.shake_offset then
		pos.row = pos.row + M.state.shake_offset.y
		pos.col = pos.col + M.state.shake_offset.x
	end

	local opts = {
		relative = "win",
		win = M.state.target_win,
		width = M.state.width,
		height = M.state.height,
		row = pos.row,
		col = pos.col,
		style = "minimal",
		border = config.border,
		focusable = false,
		noautocmd = true,
		zindex = 50,
	}

	M.state.win = api.nvim_open_win(M.state.buf, false, opts)

	if config.winblend then
		api.nvim_set_option_value("winblend", config.winblend, { win = M.state.win })
	end

	-- 设置高亮
	vim.api.nvim_set_option_value(
		"winhl",
		"Normal:SparksFloat,NormalNC:SparksFloat,NormalFloat:SparksFloat,FloatBorder:SparksFloat,EndOfBuffer:SparksFloat",
		{ win = M.state.win }
	)
end

function M.render_grid(grid)
	if not M.state.win or not api.nvim_win_is_valid(M.state.win) then
		return
	end

	api.nvim_buf_clear_namespace(M.state.buf, -1, 0, -1)

	local lines = {}
	for y = 1, M.state.height do
		local line_str = ""
		if grid[y] then
			for x = 1, M.state.width do
				local cell = grid[y][x]
				line_str = line_str .. (cell and cell.char or " ")
			end
		else
			line_str = string.rep(" ", M.state.width)
		end
		table.insert(lines, line_str)
	end

	api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)

	-- 应用高亮
	for y = 1, M.state.height do
		if grid[y] then
			for x = 1, M.state.width do
				local cell = grid[y][x]
				if cell and cell.color then
					api.nvim_buf_set_extmark(M.state.buf, api.nvim_create_namespace("Sparks"), y - 1, x - 1, {
						end_col = x,
						hl_group = cell.color,
					})
				end
			end
		end
	end
end

function M.close()
	if M.state.win and api.nvim_win_is_valid(M.state.win) then
		api.nvim_win_close(M.state.win, true)
		M.state.win = nil
	end
	M.state.buf = nil
	M.state.target_win = nil
end

function M.is_valid()
	return M.state.win and api.nvim_win_is_valid(M.state.win)
end

-- 检查窗口是否需要更新（窗口大小变化时）
function M.check_and_update(config)
	if not M.state.win or not api.nvim_win_is_valid(M.state.win) then
		return
	end

	local current_win = api.nvim_get_current_win()

	-- 如果目标窗口无效了，需要重建
	if M.state.target_win and not api.nvim_win_is_valid(M.state.target_win) then
		M.create(config)
		return
	end

	-- 如果当前编辑窗口变了，需要重建
	if M.state.target_win ~= current_win then
		M.create(config)
		return
	end

	-- 检查窗口大小是否变化
	local win_config = api.nvim_win_get_config(current_win)
	local new_width = win_config.width
	if M.state.width ~= new_width then
		-- 窗口宽度变化了，需要重建
		M.create(config)
	end
end

return M
