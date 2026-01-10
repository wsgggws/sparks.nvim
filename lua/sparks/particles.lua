local M = {}

-- 粒子类型定义
local GRAVITY = 0.2
local DRAG = 0.95

-- 状态管理
M.particles = {}
M.width = 30
M.height = 10

-- 颜色调色板 (使用 colors 模块)
local colors_mod = require("sparks.colors")

function M.init(width, height)
	M.particles = {}
	M.width = width
	M.height = height
end

-- 创建粒子
function M.spawn(x, y, count, type, text, heat_mode)
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

		local p = {
			x = x,
			y = y,
			dx = math.cos(angle) * speed,
			dy = math.sin(angle) * speed * 0.5, -- Y轴通常需要压扁一点适应字符高宽比
			life = math.random(40, 60), -- 基础寿命延长 (原 30-45)
			char = text or "*",
			color = smart_color or palette[math.random(#palette)],
			type = type, -- 'gravity', 'float', 'static'
			initial_life = 0, -- 将在下面设置
		}

		if type == "explode" then
			p.char = ({ ".", "*", "+", "x", "o" })[math.random(5)]
			p.dy = p.dy - 0.5 -- 向上爆发多一点
		elseif type == "confetti" then
			p.char = ({ ".", "o", "*", "~" })[math.random(4)]
			p.dx = (math.random() - 0.5) * 1.5
			p.dy = (math.random() - 0.5) * 1.0
			p.life = math.random(70, 90)
		elseif type == "fire" then
			p.char = ({ "^", "*", ",", "." })[math.random(4)]
			p.dy = -math.abs(p.dy) - 0.2 -- 总是向上
			p.life = math.random(70, 90)
			p.dx = p.dx * 0.5 -- 火焰横向扩散小一点
			p.x = p.x + (math.random() - 0.5) * 2 -- 稍微打散底部
		elseif type == "matrix" then
			p.char = tostring(math.random(0, 1))
			p.dx = 0
			p.dy = math.random() * 0.5 + 0.5 -- 垂直下落
			p.x = p.x + math.random(-2, 2) -- 【关键】横向随机偏移，形成宽幅代码雨
			p.color = "String" -- 通常绿色
			p.life = math.random(70, 90)
			if heat_mode == "rainbow" then
				p.color = nil
			end
		elseif type == "snow" then
			p.char = ({ "*", "·", "." })[math.random(3)]
			p.dx = (math.random() - 0.5) * 0.5 -- 左右轻微飘动
			p.dy = math.random() * 0.2 + 0.1 -- 缓慢下落
			p.color = "Comment" -- 白色或淡灰
			p.life = math.random(70, 90)
		elseif type == "heart" then
			p.char = ({ "♥", "♡" })[math.random(2)]
			p.dx = 0
			p.dy = -0.2 -- 缓缓上升
			p.color = "Red" -- 红色 (需确保有 SparksRed 高亮或 fallback)
			p.life = math.random(70, 90)
			smart_color = "Error" -- 通常是红色
		elseif type == "sparkle" then
			p.char = "✦"
			p.dx = (math.random() - 0.5) * 0.8 -- 给一点微小的漂浮移动
			p.dy = (math.random() - 0.5) * 0.8
			p.x = p.x + (math.random() - 0.5) * 3 -- 初始位置散开
			p.y = p.y + (math.random() - 0.5) * 2
			p.color = "WarningMsg"
			p.life = math.random(70, 90)
			-- 闪烁效果在 update 或 render 中处理，这里只做静态定义
		elseif type == "rain" then
			p.char = ({ "|", "!", "·" })[math.random(3)]
			p.dx = 0
			p.dy = math.random() * 0.5 + 0.5 -- 快速下落
			p.x = p.x + math.random(-2, 2) -- 宽度展开，形成雨帘
			p.color = "Function" -- 通常是蓝色
			p.life = math.random(70, 90)
		elseif type == "fizz" then
			p.char = ({ "o", "O", "." })[math.random(3)]
			p.dx = (math.random() - 0.5) * 0.5
			p.dy = -math.random() * 0.5 - 0.2 -- 向上冒泡
			p.color = "Type" -- 通常是黄色/橙色
			p.life = math.random(70, 90)
		-- 程序员的专属浪漫，我爱你们
		elseif type == "yueyue" then
			-- 🍓 草莓甜心风格
			local chars = { "🍓", "玥", "~" }
			p.char = chars[math.random(#chars)]
			p.dx = (math.random() - 0.5) * 1.4 -- 飘逸扩散
			p.dy = (math.random() - 0.5) * 0.6
			p.color = "Identifier" -- 默认粉/紫
			if p.char == "🍓" then
				p.color = "Error" -- 红色
			end
			p.life = math.random(80, 100)
		elseif type == "manman" then
			-- 🥭 芒果清新风格
			local chars = { "🥭", "曼", "~" }
			p.char = chars[math.random(#chars)]
			p.dx = (math.random() - 0.5) * 1.4 -- 飘逸扩散
			p.dy = (math.random() - 0.5) * 0.6
			p.color = "String" -- 默认绿色
			if p.char == "🥭" then
				p.color = "SparksMangoYellow" -- 这里的黄色更正
			end
			p.life = math.random(80, 100)
		elseif type == "nghuhu" then
			-- 🫖 快乐水壶风格
			local chars = { "那", "个", "胡", "🫖" }
			p.char = chars[math.random(#chars)]
			p.dx = (math.random() - 0.5) * 1.6 -- 较宽的活跃移动
			p.dy = (math.random() - 0.5) * 0.6
			p.color = "Number" -- 橙色
			if p.char == "🫖" then
				p.color = "Title" -- 白/亮色
			end
			p.life = math.random(80, 100)
		elseif type == "shenyiao" then
			-- 💊 神药爆发风格
			local chars = { "神", "药", "💊" }
			p.char = chars[math.random(#chars)]
			p.dx = (math.random() - 0.5) * 2.5 -- 极具爆发力
			p.dy = (math.random() - 0.5) * 2.5
			p.color = "Special" -- 紫色
			if p.char == "💊" then
				p.color = "WarningMsg"
			end -- 闪电黄
			p.life = math.random(80, 100)
		end

		-- 热度模式下的特殊处理
		if heat_mode == "fire" and type ~= "fire" then
			-- 即使是普通粒子，在火焰模式下也带点向上飘的特性
			p.dy = p.dy - 0.1
		end

		p.initial_life = p.life
		table.insert(M.particles, p)
	end
end

-- 更新所有粒子状态
function M.update()
	local alive_particles = {}

	for _, p in ipairs(M.particles) do
		-- 物理更新
		p.x = p.x + p.dx
		p.y = p.y + p.dy

		-- 应用重力和阻力
		if p.type == "explode" then
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
