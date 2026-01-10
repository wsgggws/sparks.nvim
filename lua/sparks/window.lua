local M = {}
local api = vim.api

-- 根据屏幕大小计算窗口尺寸
local function calculate_adaptive_size()
	local cols = vim.o.columns
	local width, height, offset

	if cols < 100 then
		-- 小屏幕 (13寸 Mac)
		width = 22
		height = 12
		offset = 3 -- 往左（增大间隙）
	elseif cols < 150 then
		-- 中等屏幕
		width = 30
		height = 16
		offset = 4 -- 往左（增大间隙）
	else
		-- 大屏幕/扩展屏
		width = 40
		height = 20
		offset = 5 -- 往左（增大间隙）
	end

	return width, height, offset
end

M.state = {
	buf = nil,
	win = nil,
	width = 20,
	height = 10,
	shake_offset = nil,
}

-- 计算窗口位置
local function get_window_position(config_pos, width, height)
	local _, _, offset = calculate_adaptive_size()
	local positions = {
		["top-right"] = { row = 0, col = vim.o.columns - width - offset }, -- row=0 往上（减小距离）
		["top-left"] = { row = 0, col = 0 },
		["bottom-right"] = { row = vim.o.lines - height - 3, col = vim.o.columns - width - offset },
		["bottom-left"] = { row = vim.o.lines - height - 3, col = 0 },
	}
	return positions[config_pos] or positions["top-right"]
end

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
	local pos = get_window_position(config_pos, M.state.width, M.state.height)

	local new_opts = {
		relative = "editor",
		row = pos.row + M.state.shake_offset.y,
		col = pos.col + M.state.shake_offset.x,
	}
	api.nvim_win_set_config(M.state.win, new_opts)

	-- 下一帧复位（或者设置一个 timer 复位，这取决于 animator 如何驱动，
	-- 这里我们简化，animator 每帧 update 时如果发现 shake_offset 会应用，然后清空）
end

function M.create(config)
	-- 自适应计算窗口大小
	local width, height, _ = calculate_adaptive_size()
	M.state.width = width
	M.state.height = height

	-- 复用窗口逻辑
	if M.state.win and api.nvim_win_is_valid(M.state.win) then
		-- 如果窗口因为某些原因变得不可见或被覆盖，可能需要重新置顶，这里暂且认为 valid 就可用
		-- 但如果已经关闭的 buffer 可能会导致问题，所以也要检查 buffer
		if M.state.buf and api.nvim_buf_is_valid(M.state.buf) then
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

	local pos = get_window_position(config.position, M.state.width, M.state.height)

	-- 震动偏移应用
	if M.state.shake_offset then
		pos.row = pos.row + M.state.shake_offset.y
		pos.col = pos.col + M.state.shake_offset.x
	end

	local opts = {
		relative = "editor",
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

function M.update(lines, highlight_group)
	if not M.state.win or not api.nvim_win_is_valid(M.state.win) then
		return
	end

	api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)

	if highlight_group then
		-- 简单应用高亮到所有行
		-- 在粒子系统中，颜色通常由粒子自身携带，这里仅作兼容或整体高亮
		for i = 0, #lines - 1 do
			api.nvim_buf_set_extmark(M.state.buf, api.nvim_create_namespace("Sparks"), i, 0, {
				end_col = -1,
				hl_group = highlight_group,
			})
		end
	end
end

-- 高级渲染：支持每个字符有不同颜色
-- grid 是一个二维数组，每个元素是 { char = "x", hl = "Group" }
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
					-- x-1 因为 api 是 0-based, end_col 是 x
					-- 注意：多字节字符可能会有偏移问题，这里假设单字节或标准宽字符处理
					-- 为了简单，粒子通常用单字节符号
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
	-- buf 会自动 wipe
	M.state.buf = nil
end

function M.is_valid()
	return M.state.win and api.nvim_win_is_valid(M.state.win)
end

return M
