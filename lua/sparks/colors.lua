local M = {}
local api = vim.api

local cache = { bufnr = -1, changedtick = -1, row = -1, col = -1, group = nil }

function M.get_cursor_hl_group()
	local bufnr = api.nvim_get_current_buf()
	local cursor = api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]
	local changedtick = vim.b[bufnr].changedtick or 0
	if cache.bufnr == bufnr and cache.changedtick == changedtick and cache.row == row and cache.col == col then
		return cache.group
	end

	local group
	if vim.treesitter.get_captures_at_pos then
		local ok, captures = pcall(vim.treesitter.get_captures_at_pos, bufnr, row, col)
		if ok and captures and #captures > 0 then
			local capture = captures[#captures]
			local name = type(capture) == "table" and capture.capture or capture
			if type(name) == "string" then
				group = name:sub(1, 1) == "@" and name or "@" .. name
			end
		end
	elseif vim.treesitter.get_captures_at_cursor then
		local ok, captures = pcall(vim.treesitter.get_captures_at_cursor, 0)
		if ok and captures and #captures > 0 then
			local name = captures[#captures]
			if type(name) == "string" then
				group = name:sub(1, 1) == "@" and name or "@" .. name
			end
		end
	end
	cache = { bufnr = bufnr, changedtick = changedtick, row = row, col = col, group = group }
	return group
end

function M.get_fallback_colors()
	return {
		"SparksString",
		"SparksNumber",
		"SparksWarning",
		"SparksComment",
		"SparksFunction",
		"Keyword",
		"SparksType",
		"SparksConstant",
		"SparksSpecial",
	}
end

function M.get_rainbow_colors()
	return {
		"SparksError",
		"SparksWarning",
		"SparksType",
		"SparksString",
		"SparksFunction",
		"SparksSpecial",
		"Directory",
	}
end

function M.get_fire_colors()
	return { "SparksWarning", "SparksError", "SparksConstant", "SparksNumber" }
end

return M
