return {
	"OXY2DEV/markview.nvim",
	lazy = false,

	-- For `nvim-treesitter` users.
	priority = 49,

	-- For blink.cmp's completion
	-- source
	dependencies = {
		"saghen/blink.cmp",
	},
	opts = {
		preview = {
			enable = false,
			enable_kybrid_mode = false,
		},
	},
}
