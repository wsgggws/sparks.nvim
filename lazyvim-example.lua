-- LazyVim 配置示例

return {
	"wsgggws/sparks.nvim",
	event = "VeryLazy",
	opts = {
		enabled = true,
		position = "top-right", -- 会根据屏幕大小自动调整位置和尺寸

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

		-- 输入/删除特效
		show_on_insert = true, -- 输入字符时显示动画
		show_on_delete = true, -- 删除字符时显示动画（仅插入模式）

		-- 🎹 特殊按键触发器
		triggers = {
			["{"] = "explode",
			["("] = "confetti",
			["}"] = "matrix",
			["*"] = "snow",
			["!"] = "explode",
			["^"] = "fire",
			["?"] = "sparkle",
			["<"] = "heart",
			[">"] = "heart",
		},

		-- 🔊 声音（自动节流 50ms，避免卡顿）
		enable_sound = true,
		sound_on_insert = true,
		sound_on_delete = true,
		sound_volume = 3.0,
		sound_pack = "default", -- mechanical, sci-fi

		-- 性能优化
		throttle = 100, -- 输入节流
		ignore_paste = true,
		disable_on_macro = true,
	},
}
