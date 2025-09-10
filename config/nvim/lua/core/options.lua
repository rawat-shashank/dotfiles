-------------------
-- vim QOL options
-------------------

-- local remaps
local opt = vim.opt

-- line number and relative line number
opt.number = true -- enable numberline
opt.relativenumber = true -- enable relative line number

-- gui appearance changes
opt.cursorline = true -- current row bg
opt.wrap = false -- don't wrap lines
opt.colorcolumn = "80,120" -- vertical col bg
opt.scrolloff = 10 -- 10 lines off on scroll
opt.signcolumn = "yes" -- enable sign coloumn
opt.tabstop = 2

-- no backup and swap for file
opt.backup = false -- don't create backup file
opt.writebackup = false -- don't write any backup
opt.swapfile = false -- don't create swap file
opt.undofile = true -- create undotree for files
opt.autochdir = false -- don't change current working dir

-- copy to windows
vim.opt.clipboard = "unnamedplus"
