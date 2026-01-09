local M = {}
local api = vim.api

-- 获取光标处的 Treesitter 高亮组名称
function M.get_cursor_hl_group()
	local bufnr = api.nvim_get_current_buf()
	local win = api.nvim_get_current_win()
	local cursor = api.nvim_win_get_cursor(win) -- row(1-based), col(0-based)
	local row, col = cursor[1] - 1, cursor[2]

	-- 尝试使用 Treesitter
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		return nil
	end

	local tree = parser:parse()[1]
	if not tree then
		return nil
	end
	local root_node = tree:root()

	-- 获取此位置最小的节点
	local node = root_node:named_descendant_for_range(row, col, row, col)
	if not node then
		return nil
	end

	-- 获取 highlight query
	local lang = parser:lang()
	local query = vim.treesitter.query.get(lang, "highlights")
	if not query then
		return nil
	end

	-- 查找匹配的 capture
	-- 注意：这需要较新版本的 Neovim API，为了兼容性可以使用 vim.treesitter.get_captures_at_cursor (0.9+)
	if vim.treesitter.get_captures_at_cursor then
		local captures = vim.treesitter.get_captures_at_cursor(0)
		if captures and #captures > 0 then
			-- 返回最具体的 capture (通常是最后一个)
			return "@" .. captures[#captures]
		end
	end

	return nil
end

-- 获取适合烟花的备选颜色列表
function M.get_fallback_colors()
	return {
		"SparksString",
		"SparksNumber",
		"SparksWarning",
		"SparksComment",
		"Function",
		"Keyword",
		"Type",
		"Constant",
		"Special",
	}
end

-- 获取彩虹色（用于 Combo 热度模式）
function M.get_rainbow_colors()
	return {
		"Error",
		"WarningMsg",
		"Type",
		"String",
		"Function",
		"Special",
		"Directory",
	}
end

-- 获取火焰色（用于 Combo 爆发模式）
function M.get_fire_colors()
	return {
		"WarningMsg",
		"Error",
		"Constant",
		"Number", -- 通常是红、黄、橙色系
	}
end

return M
