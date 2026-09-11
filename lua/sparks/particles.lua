local M = {}

-- 粒子类型定义
local GRAVITY = 0.2
local DRAG = 0.95

-- 状态管理
M.particles = {}
M.width = 30
M.height = 10

-- 颜色调色板 (使用 colors 模块和 config)
local colors_mod = require("sparks.colors")
local config_mod = require("sparks.config")

local builtin_effects = {
	confetti = true,
	explode = true,
	fire = true,
	fizz = true,
	heart = true,
	manman = true,
	matrix = true,
	nghuhu = true,
	rain = true,
	shenyiao = true,
	snow = true,
	sparkle = true,
	yueyue = true,
}
local custom_effects = {}
local default_counts = {
	confetti = 3,
	explode = 8,
	fire = 6,
	fizz = 7,
	heart = 4,
	manman = 9,
	matrix = 8,
	nghuhu = 9,
	rain = 5,
	shenyiao = 9,
	snow = 5,
	sparkle = 6,
	yueyue = 9,
}

-- 获取粒子颜色的辅助函数
local function get_particle_color(effect_type, default_hl)
	local opts = config_mod.options
	-- 如果用户配置了自定义颜色，使用用户配置
	if opts.particle_colors and opts.particle_colors[effect_type] then
		local palette = opts.particle_colors[effect_type]
		return palette[math.random(#palette)]
	end
	return default_hl
end

function M.init(width, height)
	M.particles = {}
	M.width = width
	M.height = height
end

function M.resize(width, height)
	M.width = width
	M.height = height
end

function M.clear()
	M.particles = {}
end

function M.effect_names()
	local names = {}
	for name in pairs(builtin_effects) do
		table.insert(names, name)
	end
	for name in pairs(custom_effects) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function M.default_count(name)
	local custom = custom_effects[name]
	if type(custom) == "table" and custom.count then
		return custom.count
	end
	return default_counts[name] or 3
end

function M.has_effect(name)
	return builtin_effects[name] == true or custom_effects[name] ~= nil
end

function M.register_effect(name, definition)
	if type(name) ~= "string" or name == "" then
		return false, "effect name must be a non-empty string"
	end
	if builtin_effects[name] then
		return false, "built-in effects cannot be replaced"
	end
	if type(definition) ~= "table" and type(definition) ~= "function" then
		return false, "effect definition must be a table or function"
	end
	if type(definition) == "table" then
		if type(definition.chars) ~= "table" or #definition.chars == 0 then
			return false, "effect chars must be a non-empty list"
		end
		for _, char in ipairs(definition.chars) do
			if type(char) ~= "string" or char == "" then
				return false, "effect chars must contain non-empty strings"
			end
		end
		if definition.count ~= nil and (type(definition.count) ~= "number" or definition.count < 1) then
			return false, "effect count must be at least 1"
		end
		if definition.life ~= nil then
			if
				type(definition.life) ~= "table"
				or type(definition.life[1]) ~= "number"
				or definition.life[1] < 1
				or definition.life[1] % 1 ~= 0
				or (
					definition.life[2] ~= nil
					and (
						type(definition.life[2]) ~= "number"
						or definition.life[2] < definition.life[1]
						or definition.life[2] % 1 ~= 0
					)
				)
			then
				return false, "effect life must be a positive { minimum, maximum } pair"
			end
		end
		if definition.velocity ~= nil and type(definition.velocity) ~= "function" then
			return false, "effect velocity must be a function"
		end
		if definition.update ~= nil and type(definition.update) ~= "function" then
			return false, "effect update must be a function"
		end
	end
	custom_effects[name] = definition
	return true
end

-- 创建粒子
function M.spawn(x, y, count, effect_name, text, heat_mode)
	local custom_effect = custom_effects[effect_name]
	if not builtin_effects[effect_name] and not custom_effect then
		return false
	end
	count = count or 1
	-- 获取当前上下文的颜色
	local smart_color = colors_mod.get_cursor_hl_group()
	local palette = colors_mod.get_fallback_colors()

	if heat_mode == "rainbow" then
		palette = colors_mod.get_rainbow_colors()
		smart_color = nil -- 强制多彩
	elseif heat_mode == "fire" then
		palette = colors_mod.get_fire_colors()
		smart_color = nil
	end

	for _ = 1, count do
		local angle = math.random() * math.pi * 2
		local speed = math.random() * 0.8 + 0.2

		-- 使用用户自定义颜色或默认调色板
		local default_color = get_particle_color(effect_name, palette[math.random(#palette)])

		local p = {
			x = x,
			y = y,
			dx = math.cos(angle) * speed,
			dy = math.sin(angle) * speed * 0.5, -- Y轴通常需要压扁一点适应字符高宽比
			life = math.random(40, 60), -- 基础寿命延长 (原 30-45)
			char = text or "*",
			color = smart_color or default_color,
			type = effect_name,
			initial_life = 0, -- 将在下面设置
		}

		if custom_effect then
			local context = { x = x, y = y, index = _, text = text, heat_mode = heat_mode }
			if type(custom_effect) == "function" then
				custom_effect(p, context)
			else
				if custom_effect.chars and #custom_effect.chars > 0 then
					p.char = custom_effect.chars[math.random(#custom_effect.chars)]
				end
				if custom_effect.life then
					local minimum = custom_effect.life[1] or custom_effect.life
					local maximum = custom_effect.life[2] or minimum
					p.life = math.random(minimum, maximum)
				end
				if custom_effect.velocity then
					local dx, dy = custom_effect.velocity(context)
					p.dx, p.dy = dx or p.dx, dy or p.dy
				end
				p.gravity = custom_effect.gravity
				p.drag = custom_effect.drag
				p.update_fn = custom_effect.update
			end
		elseif effect_name == "explode" then
			p.char = ({ ".", "*", "+", "x", "o" })[math.random(5)]
			p.dy = p.dy - 0.5 -- 向上爆发多一点
		elseif effect_name == "confetti" then
			p.char = ({ ".", "o", "*", "~" })[math.random(4)]
			p.dx = (math.random() - 0.5) * 1.5
			p.dy = (math.random() - 0.5) * 1.0
			p.life = math.random(70, 90)
		elseif effect_name == "fire" then
			p.char = ({ "^", "*", ",", "." })[math.random(4)]
			p.dy = -math.abs(p.dy) - 0.2 -- 总是向上
			p.life = math.random(70, 90)
			p.dx = p.dx * 0.5 -- 火焰横向扩散小一点
			p.x = p.x + (math.random() - 0.5) * 2 -- 稍微打散底部
		elseif effect_name == "matrix" then
			p.char = tostring(math.random(0, 1))
			p.dx = 0
			p.dy = math.random() * 0.5 + 0.5 -- 垂直下落
			p.x = p.x + math.random(-2, 2) -- 【关键】横向随机偏移，形成宽幅代码雨
			p.color = get_particle_color("matrix", "String") -- 通常绿色
			p.life = math.random(70, 90)
		elseif effect_name == "snow" then
			p.char = ({ "*", "·", "." })[math.random(3)]
			p.dx = (math.random() - 0.5) * 0.5 -- 左右轻微飘动
			p.dy = math.random() * 0.2 + 0.1 -- 缓慢下落
			p.color = get_particle_color("snow", "Comment") -- 白色或淡灰
			p.life = math.random(70, 90)
		elseif effect_name == "heart" then
			p.char = ({ "♥", "♡" })[math.random(2)]
			p.dx = 0
			p.dy = -0.2 -- 缓缓上升
			p.color = get_particle_color("heart", "Error") -- 红色
			p.life = math.random(70, 90)
			smart_color = nil
		elseif effect_name == "sparkle" then
			p.char = "✦"
			p.dx = (math.random() - 0.5) * 0.8 -- 给一点微小的漂浮移动
			p.dy = (math.random() - 0.5) * 0.8
			p.x = p.x + (math.random() - 0.5) * 3 -- 初始位置散开
			p.y = p.y + (math.random() - 0.5) * 2
			p.color = get_particle_color("sparkle", "WarningMsg")
			p.life = math.random(70, 90)
			-- 闪烁效果在 update 或 render 中处理，这里只做静态定义
		elseif effect_name == "rain" then
			p.char = ({ "|", "!", "·" })[math.random(3)]
			p.dx = 0
			p.dy = math.random() * 0.5 + 0.5 -- 快速下落
			p.x = p.x + math.random(-2, 2) -- 宽度展开，形成雨帘
			p.color = get_particle_color("rain", "Function") -- 通常是蓝色
			p.life = math.random(70, 90)
		elseif effect_name == "fizz" then
			p.char = ({ "o", "O", "." })[math.random(3)]
			p.dx = (math.random() - 0.5) * 0.5
			p.dy = -math.random() * 0.5 - 0.2 -- 向上冒泡
			p.color = get_particle_color("fizz", "Type") -- 通常是黄色/橙色
			p.life = math.random(70, 90)
		-- 程序员的专属浪漫，我爱你们
		elseif effect_name == "yueyue" then
			-- 🍓 草莓甜心风格
			local chars = { "🍓", "玥", "~" }
			p.char = chars[math.random(#chars)]
			p.dx = (math.random() - 0.5) * 1.4 -- 飘逸扩散
			p.dy = (math.random() - 0.5) * 0.6
			p.color = get_particle_color("yueyue", "Identifier") -- 默认粉/紫
			if p.char == "🍓" then
				p.color = get_particle_color("heart", "Error") -- 红色
			end
			p.life = math.random(80, 100)
		elseif effect_name == "manman" then
			-- 🥭 芒果清新风格
			local chars = { "🥭", "曼", "~" }
			p.char = chars[math.random(#chars)]
			p.dx = (math.random() - 0.5) * 1.4 -- 飘逸扩散
			p.dy = (math.random() - 0.5) * 0.6
			p.color = get_particle_color("manman", "String") -- 默认绿色
			if p.char == "🥭" then
				p.color = get_particle_color("manman", "Number") -- 这里的黄色更正
			end
			p.life = math.random(80, 100)
		elseif effect_name == "nghuhu" then
			-- 🫖 快乐水壶风格
			local chars = { "那", "个", "胡", "🫖" }
			p.char = chars[math.random(#chars)]
			p.dx = (math.random() - 0.5) * 1.6 -- 较宽的活跃移动
			p.dy = (math.random() - 0.5) * 0.6
			p.color = get_particle_color("nghuhu", "Number") -- 橙色
			if p.char == "🫖" then
				p.color = get_particle_color("sparkle", "Title") -- 白/亮色
			end
			p.life = math.random(80, 100)
		elseif effect_name == "shenyiao" then
			-- 💊 神药爆发风格
			local chars = { "神", "药", "💊" }
			p.char = chars[math.random(#chars)]
			p.dx = (math.random() - 0.5) * 2.5 -- 极具爆发力
			p.dy = (math.random() - 0.5) * 2.5
			p.color = get_particle_color("shenyiao", "Special") -- 紫色
			if p.char == "💊" then
				p.color = get_particle_color("sparkle", "WarningMsg")
			end -- 闪电黄
			p.life = math.random(80, 100)
		end

		if heat_mode and not custom_effect then
			p.color = palette[math.random(#palette)]
		end

		-- 热度模式下的特殊处理
		if heat_mode == "fire" and effect_name ~= "fire" then
			-- 即使是普通粒子，在火焰模式下也带点向上飘的特性
			p.dy = p.dy - 0.1
		end

		local opts = config_mod.options
		if not custom_effect or (type(custom_effect) == "table" and not custom_effect.life) then
			local base_life = math.max(1, math.floor((opts.duration / 1000) * opts.animation_fps))
			local minimum = math.max(1, math.floor(base_life * 0.7))
			p.life = math.random(minimum, base_life)
		end
		p.initial_life = p.life
		while #M.particles >= (opts.max_particles or 180) do
			table.remove(M.particles, 1)
		end
		table.insert(M.particles, p)
	end
	return true
end

-- 更新所有粒子状态
function M.update()
	local alive_particles = {}

	for _, p in ipairs(M.particles) do
		-- 物理更新
		p.x = p.x + p.dx
		p.y = p.y + p.dy

		-- 应用重力和阻力
		if p.update_fn then
			p.update_fn(p)
		elseif p.gravity or p.drag then
			p.dy = p.dy + (p.gravity or 0)
			p.dx = p.dx * (p.drag or 1)
			p.dy = p.dy * (p.drag or 1)
		elseif p.type == "explode" then
			p.dy = p.dy + GRAVITY
			p.dx = p.dx * DRAG
			p.dy = p.dy * DRAG
		elseif p.type == "confetti" then
			p.dy = p.dy + 0.05 -- 轻微重力
			p.dx = p.dx * 0.98 -- 空气阻力
		elseif p.type == "fizz" then
			p.dx = p.dx + (math.random() - 0.5) * 0.1 -- 气泡左右摇摆
		end

		-- 视觉淡出效果 (Visual Fading)
		if p.initial_life > 0 then
			local ratio = p.life / p.initial_life
			if ratio < 0.3 then
				-- 生命最后 30% 变为极小的点
				p.char = "·"
			elseif ratio < 0.6 then
				-- 生命最后 60% 变为小点
				p.char = "."
			end
		end

		--

		p.life = p.life - 1

		-- 边界检查 (简单的环绕或消失)
		if p.x >= 1 and p.x <= M.width and p.y >= 1 and p.y <= M.height and p.life > 0 then
			table.insert(alive_particles, p)
		end
	end

	M.particles = alive_particles
	return #M.particles > 0
end

-- 渲染为 Grid 数据结构供 Window 渲染
function M.generate_grid()
	local grid = {}
	for y = 1, M.height do
		grid[y] = {}
	end

	for _, p in ipairs(M.particles) do
		local ix = math.floor(p.x + 0.5)
		local iy = math.floor(p.y + 0.5)

		if ix >= 1 and ix <= M.width and iy >= 1 and iy <= M.height then
			grid[iy][ix] = { char = p.char, color = p.color }
		end
	end

	return grid
end

-- 辅助：添加单个显示文本（作为固定粒子或中心对象）
function M.add_text()
	-- 未来扩展：在这里处理静态文本展示逻辑
end

return M
