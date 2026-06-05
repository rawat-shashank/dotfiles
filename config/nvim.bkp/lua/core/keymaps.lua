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
vim.keymap.set("n", "<leader>ci", function()
	vim.cmd("normal! A [clock::" .. os.date("%Y-%m-%dT%H:%M:%S") .. "")
end, { desc = "[C]lock [I]n current date and time" })

vim.keymap.set("n", "<leader>co", function()
	vim.cmd("normal! A--" .. os.date("%Y-%m-%dT%H:%M:%S") .. "]")
end, { desc = "[C]lock [O]ut current date and time" })

-- Iterate through pending tasks in telescope
vim.keymap.set("n", "<leader>tp", function()
	require("telescope.builtin").grep_string({
		prompt_title = "Incomplete Tasks",
		initial_mode = "insert",
		search = "^\\s*- \\[ \\]",
		search_dirs = { vim.fn.getcwd() }, -- Restrict search to the current working directory
		use_regex = true, -- Enable regex for the search term
		additional_args = { "--no-ignore" },
	})
end, { desc = "[T]asks [P]ending list and search" })

-- Iterate through completed tasks in telescope
vim.keymap.set("n", "<leader>tp", function()
	require("telescope.builtin").grep_string({
		prompt_title = "Incomplete Tasks",
		initial_mode = "insert",
		search = "^\\s*- \\[ \\]",
		search_dirs = { vim.fn.getcwd() }, -- Restrict search to the current working directory
		use_regex = true, -- Enable regex for the search term
		additional_args = { "--no-ignore" },
	})
end, { desc = "[T]asks [P]ending list and search" })

-- Toggle Markview splitOpen
vim.keymap.set("n", "<leader>pt", ":Markview splitToggle<CR>", { desc = "[P]review [T]oggle - Markview" })
