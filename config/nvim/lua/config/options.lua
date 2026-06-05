-------------------
-- vim QOL options
-------------------

-- local remaps
local opt = vim.opt

-- line number and relative line number
opt.number = true -- enable numberline
opt.relativenumber = true -- enable relative line number
opt.wrap = false -- don't wrap lines
opt.cursorline = true -- current row bg

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

-- gui appearance changes
opt.termguicolors = true
opt.cursorline = true -- current row bg
opt.colorcolumn = "80,120" -- vertical col bg
opt.scrolloff = 10 -- 10 lines off on scroll
opt.signcolumn = "yes" -- enable sign coloumn
opt.showmatch = true -- Highlight matching columns
opt.conceallevel = 2

-- no backup and swap for file
opt.backup = false -- don't create backup file
opt.writebackup = false -- don't write any backup
opt.swapfile = false -- don't create swap file
opt.undofile = true -- create undotree for files
opt.autochdir = false -- don't change current working dir

-- copy to windows
opt.mouse = "a"
opt.clipboard = "unnamedplus"

-- Folding settings
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldlevel = 99 -- Start with all folds open
vim.o.foldlevelstart = 99 -- Start with all folds open
vim.o.smoothscroll = true
vim.o.foldminlines = 1

-- =============================
-- Highlight when yanking (copying) text
--  See `:help vim.highlight.on_yank()`
-- =============================
local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = augroup("kickstart-highlight-yank", {
		clear = true,
	}),
	callback = function()
		vim.highlight.on_yank()
	end,
})
