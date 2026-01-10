local M = {}

M.defaults = {
	enabled = true,
	position = "top-right", -- top-right, top-left, bottom-right, bottom-left
	duration = 1200, -- 动画持续时间(ms)
	throttle = 30, -- 节流时间(ms)
	border = "none", -- none, single, double, rounded, solid, shadow
	show_on_insert = true,
	show_on_delete = true,
	-- 特殊字符动画
	special_char_animation = true, -- 为特殊字符启用特殊动画
	-- 动画效果
	animation_fps = 30, -- 动画帧率 (粒子系统使用较高帧率以保证流畅)
	animation_style = "bounce", -- bounce, fade, slide, spin, wave
	-- 声音效果
	enable_sound = true, -- 启用声音（默认关闭）
	sound_on_insert = true, -- 输入时播放声音
	sound_on_delete = true, -- 删除时播放声音
	sound_volume = 3.0, -- 音量 (0.0 - 5.0)
	-- 可配置多个声音文件，随机选择一个播放
	-- 如果为空或 nil，将使用系统默认声音
	sound_file_insert = nil, -- 输入时的声音文件列表 (nil = 使用系统默认)
	sound_file_delete = nil, -- 删除时的声音文件列表 (nil = 使用系统默认)
	sound_pack = "default", -- none, default, mechanical, sci-fi (如果设置了 sound_file_*，则忽略此项)

	-- Combo (连击) 系统
	enable_combo = true,
	combo_threshold = 5,
	combo_timeout = 2000,
	heat_map = {
		[10] = "rainbow", -- 连击 > 10 开启彩虹粒子
		[20] = "fire", -- 连击 > 20 开启火焰模式
	},

	-- 震动效果
	enable_shake = true, -- 开启窗口震动
	shake_intensity = 1, -- 震动强度

	-- 高级触发器
	triggers = {
		["{"] = "explode", -- 输入 { 触发爆炸
		["("] = "confetti", -- 输入 ( 触发彩带
		["}"] = "matrix", -- 代码块关闭
		["*"] = "snow", -- 星号雪花
		["^"] = "fire", -- 乘方火焰
		["!"] = "explode", -- 惊叹号爆炸
		["?"] = "sparkle", -- 问号闪烁
		["<"] = "heart", -- 爱心
		[">"] = "heart", -- 爱心
	},

	-- 性能优化
	ignore_paste = true, -- 在粘贴模式下禁用动画
	disable_on_macro = true, -- 在宏录制/播放时禁用动画

	-- 外观配置
	winblend = 0, -- 窗口透明度 (0-100)，设置为 10-20 可以让背景更自然

	-- 🛡️ 智能屏蔽 (列表中的 filetype 或 buftype 将不触发动画)
	excluded_filetypes = { "TelescopePrompt", "NvimTree", "neo-tree", "lazy", "mason", "dashboard" },
	excluded_buftypes = { "nofile", "terminal", "prompt" },
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
