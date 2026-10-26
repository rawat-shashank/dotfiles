-------------------------------------------------------------------------------
-- 1. Declarative Plugin Installation (`vim.pack.add`)
-------------------------------------------------------------------------------
vim.pack.add({
	-- theming
	{ src = "https://github.com/catppuccin/nvim" },

	-- Yazi File Manager
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/mikavilpas/yazi.nvim" },

	-- FZF-Lua
	{ src = "https://github.com/ibhagwan/fzf-lua" },

	-- Blink.cmp
	{
		src = "https://github.com/Saghen/blink.cmp",
		version = vim.version.range("^1"),
		build = "cargo build --release",
	},

	-- Mason & Integrations
	{ src = "https://github.com/williamboman/mason.nvim" },
	{ src = "https://github.com/williamboman/mason-lspconfig.nvim" },
	{ src = "https://github.com/zapling/mason-conform.nvim" },

	-- Formatting & LSP
	{ src = "https://github.com/stevearc/conform.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },

	-- Mini plugins Configs
	{ src = "https://github.com/echasnovski/mini.pairs" },
	{ src = "https://github.com/echasnovski/mini.icons", version = "stable" },

	-- treesitter
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter",
		version = "main",
	},

	-- Misc
	{ src = "https://github.com/christoomey/vim-tmux-navigator" },
	{ src = "https://github.com/folke/which-key.nvim" },
})

-------------------------------------------------------------------------------
-- 2. Plugin Setup
-------------------------------------------------------------------------------
require("yazi").setup({ open_for_directories = true })
require("fzf-lua").setup({})
require("which-key").setup({ preset = "helix" })
require("mini.pairs").setup()
require("mini.icons").setup()

require("blink.cmp").setup({
	keymap = { preset = "default" },
	sources = { default = { "lsp", "path", "snippets", "buffer" } },
})

require("mason").setup()

require("conform").setup({
	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback",
	},
	formatters_by_ft = {
		bash = { "shfmt" },
		sh = { "shfmt" },
		lua = { "stylua" },
		javascript = { "prettier" },
		typescript = { "prettier" },
	},
})

require("mason-conform").setup({
	ensure_installed = { "shfmt", "stylua", "prettier" },
	automatic_installation = true,
})

require("catppuccin").setup({
	transparent_background = false,
})
vim.cmd.colorscheme("catppuccin-mocha")
