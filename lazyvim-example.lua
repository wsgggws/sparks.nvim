return {
	"wsgggws/sparks.nvim",
	event = "VeryLazy",
	opts = {
		preset = "power",
		position = "right-center",
		render = {
			radius = 6,
		},
		enable_sound = false,
		integrations = {
			save = { enabled = true, effect = "sparkle", intensity = 1 },
			diagnostics_clear = { enabled = true, effect = "confetti", intensity = 2 },
		},
	},
}
