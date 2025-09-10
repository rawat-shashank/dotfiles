-------------------
-- vim key re-maps
-------------------

-- add leader key to space
vim.g.mapleader = " "

-- local variale
local keymap = vim.keymap

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", { noremap = true, silent = true, desc = "exit insert mode using jk"})
