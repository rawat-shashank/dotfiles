-------------------
-- vim key re-maps
-------------------

vim.g.mapleader = " "
local keymap = vim.keymap

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>")

-- save and exit remaps
keymap.set("n", "<C-s>", "<ESC>:w<CR>")
keymap.set("n", "<C-w>", "<ESC>:wq<CR>")
keymap.set("n", "<C-q>", "<ESC>:q!<CR>")

-- delete single character without copying into register
--keymap.set("n", "x", "_x")

-- tab management
keymap.set("n", "<leader>to", ":tabnew<CR>")   -- open new tab
keymap.set("n", "<leader>tx", ":tabclose<CR>") -- close current tab
keymap.set("n", "<leader>tn", ":tabn<CR>")     -- go to next tab
keymap.set("n", "<leader>tp", ":tabp<CR>")     -- go to previous tab
