-- LazyVim 配置示例
-- 将此文件放到 ~/.config/nvim/lua/plugins/sparks.lua

return {
	"wsgggws/sparks.nvim",
	event = "VeryLazy",

	opts = {
		enabled = true,
		position = "top-right",

		-- 🚀 粒子系统
		animation_fps = 30,

		-- 🔥 Combo 系统
		enable_combo = true,
		combo_threshold = 5,
		combo_timeout = 2000,
		heat_map = {
			[10] = "rainbow", -- >10连击：彩虹模式
			[20] = "fire", -- >20连击：火焰模式
		},

		-- 🫨 震动反馈
		enable_shake = true,
		shake_intensity = 1,

		-- 🎹 特殊按键触发器
		triggers = {
			["{"] = "explode",
			["("] = "confetti",
			["}"] = "matrix",
			["*"] = "snow",
			["!"] = "explode",
			["^"] = "fire",
		},

		-- 🔊 声音
		enable_sound = true,
		sound_pack = "default", -- mechanical, sci-fi
	},
}
