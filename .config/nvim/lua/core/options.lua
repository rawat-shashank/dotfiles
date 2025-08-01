-- vim settings
local opt = vim.opt
local api = vim.api

-- line number and relative line number
opt.number = true
opt.relativenumber = true
opt.wrap = false
opt.cursorline = true

-- tabs & indentation
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

-- search settings
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- appreance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.scrolloff = 10
opt.colorcolumn = "80,120"

-- file handling
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.autoread = true
opt.autochdir = false

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
	group = api.nvim_create_augroup("kickstart-highlight-yank", {
		clear = true,
	}),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Return to last edit position when opening files
api.nvim_create_autocmd("BufReadPost", {
	desc = "Return to last edit position when opening files",
	group = augroup,
	callback = function()
		local mark = api.nvim_buf_get_mark(0, '"')
		local lcount = api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(api.nvim_win_set_cursor, 0, mark)
		end
	end,
})
