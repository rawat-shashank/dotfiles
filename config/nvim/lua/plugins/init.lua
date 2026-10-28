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
		json = { "prettier" },
		markdown = { "prettier" },
	},
})

require("mason-conform").setup({
	ensure_installed = { "shfmt", "stylua", "prettier" },
	automatic_installation = true,
})

require("catppuccin").setup({
	transparent_background = false,
	custom_highlights = function(colors)
		return {
			-- Treesitter Heading Highlights (Neovim 0.9+)
			["@markup.heading.1.markdown"] = { fg = colors.red, bold = true, style = { "bold" } },
			["@markup.heading.2.markdown"] = { fg = colors.peach, bold = true },
			["@markup.heading.3.markdown"] = { fg = colors.yellow, bold = true },
			["@markup.heading.4.markdown"] = { fg = colors.green, bold = true },
			["@markup.heading.5.markdown"] = { fg = colors.blue, bold = true },
			["@markup.heading.6.markdown"] = { fg = colors.lavender, bold = true },

			-- Standard Vim Regex Highlights (Fallback for non-treesitter)
			markdownH1 = { fg = colors.red, bold = true },
			markdownH2 = { fg = colors.peach, bold = true },
			markdownH3 = { fg = colors.yellow, bold = true },
			markdownH4 = { fg = colors.green, bold = true },
			markdownH5 = { fg = colors.blue, bold = true },
			markdownH6 = { fg = colors.lavender, bold = true },
		}
	end,
})
vim.cmd.colorscheme("catppuccin-mocha")
