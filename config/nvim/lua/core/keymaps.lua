-------------------
-- vim key re-maps
-------------------

-- add leader key to space
vim.g.mapleader = " "

-- local variale
local keymap = vim.keymap

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", { noremap = true, silent = true, desc = "exit insert mode using jk" })

-- obsidian clock in and clock out
vim.keymap.set(
	"n",
	"<leader>ci",
	"i[clock::" .. os.date("%Y-%m-%dT%H:%M:%S") .. "<Esc>",
	{ desc = "[C]lock [I]n current date and time" }
)

vim.keymap.set(
	"n",
	"<leader>co",
	"a--" .. os.date("%Y-%m-%dT%H:%M:%S") .. "]<Esc>",
	{ desc = "[C]lock [O]ut current date and time" }
)
