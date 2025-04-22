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
keymap.set("n", "<leader>to", ":tabnew<CR>", opts)   -- open new tab
keymap.set("n", "<leader>tx", ":tabclose<CR>", opts) -- close current tab
keymap.set("n", "<leader>tn", ":tabn<CR>", opts)     -- go to next tab
keymap.set("n", "<leader>tp", ":tabp<CR>", opts)     -- go to previous tab
