local M = {}

local config_mod = require("sparks.config")
local window = require("sparks.window")
local sound = require("sparks.sound")
local particles = require("sparks.particles")
local api = vim.api
local uv = vim.uv or vim.loop

local state = {
	timer = nil,
	last_trigger = 0,
	combo_count = 0,
	last_activity = 0,
	is_animating = false,
	active_text = nil, -- 当前显示的主文本
}

-- 节流
local function throttle()
	local now = uv.now()
	if now - state.last_trigger < config_mod.options.throttle then
		return false
	end
	state.last_trigger = now
	return true
end

-- 动画循环
local function start_animation_loop()
	if state.timer then
		return
	end

	-- 使用与窗口相同的自适应大小
	local cols = vim.o.columns
	local width, height
	if cols < 100 then
		width, height = 16, 8
	elseif cols < 150 then
		width, height = 20, 10
	else
		width, height = 26, 12
	end

	if particles.width == 0 or particles.height == 0 then
		particles.width = width
		particles.height = height
	end
	window.create(config_mod.options)

	state.timer = uv.new_timer()
	local tick_rate = math.floor(1000 / config_mod.options.animation_fps)

	state.timer:start(
		0,
		tick_rate,
		vim.schedule_wrap(function()
			if not window.is_valid() then
				-- 尝试重建窗口
				window.create(config_mod.options)
				if not window.is_valid() then
					-- 如果还是失败，可能不适合继续
					if state.timer then
						state.timer:stop()
						state.timer:close()
						state.timer = nil
					end
					return
				end
			end

			-- 1. 更新粒子
			local has_particles = particles.update()

			-- 2. 检查 Combo 超时
			local now = uv.now()
			local timeout = config_mod.options.combo_timeout

			-- 若无连击，文本只需短暂停留 (如删除操作)
			if state.combo_count == 0 then
				timeout = 500
			end

			if now - state.last_activity > timeout then
				state.combo_count = 0
				state.active_text = nil
			end

			-- 3. 如果没有粒子也没 Combo 显示，停止循环
			if not has_particles and state.combo_count == 0 and not state.active_text then
				if state.timer then
					state.timer:stop()
					state.timer:close()
					state.timer = nil
				end
				window.close()
				return
			end

			-- 4. 生成渲染网格
			local grid = particles.generate_grid()

			-- 5. 将主文本 (Combo 或 当前字符) 叠加到网格中心
			if state.active_text then
				local cx = math.floor(particles.width / 2) - math.floor(#state.active_text / 2)
				local cy = math.floor(particles.height / 2)
				for i = 1, #state.active_text do
					local char = state.active_text:sub(i, i)
					if grid[cy] and grid[cy][cx + i] == nil then
						-- 只有本格子没有粒子时才覆盖，或者粒子可以覆盖文字
						grid[cy][cx + i] = { char = char, color = "SparksString" }
					end
				end

				-- 如果有 Combo，在下方显示
				if config_mod.options.enable_combo and state.combo_count >= config_mod.options.combo_threshold then
					local combo_str = string.format("x%d", state.combo_count)
					local cx2 = math.floor(particles.width / 2) - math.floor(#combo_str / 2)
					local cy2 = cy + 2
					if grid[cy2] then
						for i = 1, #combo_str do
							local char = combo_str:sub(i, i)
							grid[cy2][cx2 + i] = { char = char, color = "SparksWarning" }
						end
					end
				end
			end

			-- 6. 渲染
			window.render_grid(grid)
		end)
	)
end

local function trigger_effect(char, type)
	-- 0. 智能屏蔽 (Smart Exclude)
	-- 检查 filetype
	if vim.tbl_contains(config_mod.options.excluded_filetypes, vim.bo.filetype) then
		return
	end
	-- 检查 buftype
	if vim.tbl_contains(config_mod.options.excluded_buftypes, vim.bo.buftype) then
		return
	end

	-- 性能检查：粘贴模式或宏录制时禁用
	if config_mod.options.ignore_paste and vim.o.paste then
		return
	end
	if config_mod.options.disable_on_macro and vim.fn.reg_recording() ~= "" then
		return
	end
	if config_mod.options.disable_on_macro and vim.fn.reg_executing() ~= "" then
		return
	end

	-- 检查自定义触发器
	local anim_type = "confetti"
	if type == "insert" then
		if config_mod.options.triggers[char] then
			anim_type = config_mod.options.triggers[char]
		end
	else
		-- 删除操作使用爆炸效果
		anim_type = "explode"
	end

	local now = uv.now()
	state.last_activity = now

	-- 更新 Combo
	if type == "insert" then
		state.combo_count = state.combo_count + 1
	elseif type == "delete" then
		-- 删除不增加 combo
	end

	-- 计算热度等级
	local heat_mode = nil
	if config_mod.options.heat_map then
		for threshold, mode in pairs(config_mod.options.heat_map) do
			if state.combo_count >= threshold then
				-- 简单的优先级逻辑：更高的阈值可能需要覆盖
				if mode == "fire" then
					heat_mode = "fire"
				end
				if mode == "rainbow" and heat_mode ~= "fire" then
					heat_mode = "rainbow"
				end
			end
		end
	end

	-- 触发粒子
	local center_x = math.floor(particles.width / 2)
	local center_y = math.floor(particles.height / 2)

	if type == "insert" then
		state.active_text = char
		-- 每次按键发射少量粒子进行装饰
		particles.spawn(center_x, center_y, 3, anim_type, char, heat_mode)

		-- Combo 达到一定程度，释放更多
		if state.combo_count > 0 and state.combo_count % 10 == 0 then
			particles.spawn(center_x, center_y, 10, "explode", "*", heat_mode)
			-- 震动效果
			if config_mod.options.enable_shake then
				window.shake(config_mod.options.shake_intensity or 1)
				-- 100ms 后复位
				vim.defer_fn(function()
					window.shake(0)
				end, 50)
			end
		end

		sound.play("insert", config_mod.options)
	elseif type == "delete" then
		state.active_text = nil
		particles.spawn(center_x, center_y, 8, "explode", char, heat_mode)
		sound.play("delete", config_mod.options)

		-- 删除也震动一下
		if config_mod.options.enable_shake then
			window.shake(1)
			vim.defer_fn(function()
				window.shake(0)
			end, 50)
		end
	end

	-- 启动循环 (使用 schedule 避免 textlock)
	vim.schedule(start_animation_loop)
end

local function setup_autocmds()
	local group = api.nvim_create_augroup("Sparks", { clear = true })
	local opts = config_mod.options

	if opts.show_on_insert then
		api.nvim_create_autocmd("InsertCharPre", {
			group = group,
			callback = function()
				if not throttle() then
					return
				end
				trigger_effect(vim.v.char, "insert")
			end,
		})

		-- 退出插入模式时立即清理状态
		api.nvim_create_autocmd("InsertLeave", {
			group = group,
			callback = function()
				state.active_text = nil
				-- 保持 combo_count 还是清零取决于设计，这里选择清零以符合直觉
				state.combo_count = 0
			end,
		})
	end

	if opts.show_on_delete then
		-- 将 prev_* 变量提升到函数作用域，方便 InsertCharPre 也能访问和更新
		local prev_line_count = -1
		local prev_line_content = ""
		local prev_row = -1
		local is_insert_char = false -- 标记是否正在输入字符

		local function sync_state()
			if not api.nvim_buf_is_valid(0) then
				return
			end
			prev_line_count = api.nvim_buf_line_count(0)
			local cursor = api.nvim_win_get_cursor(0)
			prev_row = cursor[1]
			local lines = api.nvim_buf_get_lines(0, prev_row - 1, prev_row, false)
			prev_line_content = lines[1] or ""
		end

		-- 立即初始化
		if api.nvim_buf_is_valid(0) then
			sync_state()
		end

		-- 如果插件加载时已经在插入模式中，立即同步状态
		local current_mode = api.nvim_get_mode().mode
		if current_mode:match("^[iR]") then
			sync_state()
		end

		-- 在字符输入前设置标记并同步状态
		api.nvim_create_autocmd("InsertCharPre", {
			group = group,
			callback = function()
				is_insert_char = true
				sync_state()
			end,
		})

		api.nvim_create_autocmd("TextChangedI", {
			group = group,
			callback = function()
				if is_insert_char then
					is_insert_char = false
					sync_state()
					return
				end

				local curr_line_count = api.nvim_buf_line_count(0)
				local cursor = api.nvim_win_get_cursor(0)
				local curr_row = cursor[1]
				local curr_line_content = api.nvim_buf_get_lines(0, curr_row - 1, curr_row, false)[1] or ""

				-- 如果有之前的状态，验证确实是删除
				local is_confirmed_delete = false
				if prev_line_count ~= -1 then
					if curr_line_count < prev_line_count then
						is_confirmed_delete = true
					elseif curr_line_count == prev_line_count and #curr_line_content < #prev_line_content then
						is_confirmed_delete = true
					end
				end

				if prev_line_count == -1 or is_confirmed_delete then
					trigger_effect("X", "delete")
				end

				sync_state()
			end,
		})

		api.nvim_create_autocmd("CursorMovedI", {
			group = group,
			callback = function()
				local curr_cnt = api.nvim_buf_line_count(0)
				if curr_cnt == prev_line_count then
					local cursor = api.nvim_win_get_cursor(0)
					if cursor[1] ~= prev_row then
						sync_state()
					end
				end
			end,
		})

		-- 进入插入模式时立即同步，不使用异步延迟
		api.nvim_create_autocmd("InsertEnter", {
			group = group,
			callback = function()
				sync_state()
			end,
		})
	end
end

function M.setup(opts)
	config_mod.setup(opts)
	if not config_mod.options.enabled then
		return
	end

	-- 诊断：检测加载时机
	local current_mode = api.nvim_get_mode().mode
	if current_mode:match("^[iR]") then
		vim.notify(
			"Sparks: 插件在插入模式中加载。如果删除动画不工作，请将加载事件改为 'InsertEnter'",
			vim.log.levels.WARN
		)
	end

	-- 设置高亮
	-- 使用 bg=NONE 以支持透明背景和 winblend
	vim.api.nvim_set_hl(0, "SparksFloat", { bg = "NONE", fg = "NONE" })

	local function create_nobg_hl(name, base)
		local hl = vim.api.nvim_get_hl(0, { name = base, link = false })
		-- 这里的 bg 设为 NONE，否则每个字符会有不透明的背景框
		vim.api.nvim_set_hl(0, name, { fg = hl.fg, bg = "NONE", bold = hl.bold, italic = hl.italic })
	end
	create_nobg_hl("SparksString", "String")
	create_nobg_hl("SparksNumber", "Number")
	create_nobg_hl("SparksWarning", "WarningMsg")
	create_nobg_hl("SparksComment", "Comment")

	setup_autocmds()

	-- 命令
	vim.api.nvim_create_user_command("SparksToggle", function()
		config_mod.options.enabled = not config_mod.options.enabled
		vim.notify("Sparks: " .. (config_mod.options.enabled and "enabled" or "disabled"))
	end, {})

	vim.api.nvim_create_user_command("SparksTest", function()
		trigger_effect("T", "insert")
		vim.defer_fn(function()
			trigger_effect("E", "insert")
		end, 200)
		vim.defer_fn(function()
			trigger_effect("S", "insert")
		end, 400)
		vim.defer_fn(function()
			trigger_effect("T", "insert")
		end, 600)
		vim.defer_fn(function()
			trigger_effect("!", "explode")
		end, 1000)
	end, {})
end

return M
