-------------------
-- vim key re-maps
-------------------

vim.g.mapleader = " "
local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", opts)

-- save and exit remaps
keymap.set("n", "<C-s>", "<ESC>:w<CR>", opts)
keymap.set("n", "<C-w>", "<ESC>:wq<CR>", opts)
keymap.set("n", "<C-q>", "<ESC>:q!<CR>", opts)

-- delete single character without copying into register
--keymap.set("n", "x", "_x")

-- tab management
keymap.set("n", "<leader>to", ":tabnew<CR>", opts) -- open new tab
keymap.set("n", "<leader>tx", ":tabclose<CR>", opts) -- close current tab
keymap.set("n", "<leader>tn", ":tabn<CR>", opts) -- go to next tab
keymap.set("n", "<leader>tp", ":tabp<CR>", opts) -- go to previous tab

-- center screen when jumping
keymap.set("n", "n", "nzzzv", opts)
keymap.set("n", "N", "Nzzzv", opts)
keymap.set("n", "<C-d>", "<C-d>zz", opts)
keymap.set("n", "<C-u>", "<C-u>zz", opts)

-- Move lines up/down
opts.desc = "[A]lt + [j] Move current line down"
keymap.set("n", "<A-j>", ":m .+1<CR>==", opts)
opts.desc = "[A]lt + [k] Move current line up"
keymap.set("n", "<A-k>", ":m .-2<CR>==", opts)
opts.desc = "[A]lt + [j] Visual selected lines down"
keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", opts)
opts.desc = "[A]lt + [j] Visual selected lines up"
keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", opts)

-- Better indenting in visual mode
keymap.set("v", "<", "<gv", opts)
keymap.set("v", ">", ">gv", opts)
