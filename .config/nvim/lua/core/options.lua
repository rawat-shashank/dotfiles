-- vim settings
local opt = vim.opt
local api = vim.api

-- line number and relative line number
opt.number = true
opt.relativenumber = true

-- tabs & indentation
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

--line wrapping
opt.wrap = false

-- search settings
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false

-- cursor line
opt.cursorline = true

-- appreance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.colorcolumn = "80,120"

-- backspace
opt.backspace = "indent,eol,start"

-- copy to windows
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", {
		clear = true,
	}),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- force neo-tree to not update cwd itself
opt.autochdir = false
