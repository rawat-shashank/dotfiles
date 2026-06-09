-- ==========================
-- vim-tmux-navigator
-- ==========================

vim.pack.add({ "https://github.com/nvim-telescope/telescope.nvim" })
vim.pack.add({ "https://github.com/nvim-lua/plenary.nvim" })

-- ==========================================================================
-- Configuration & Setup
-- ==========================================================================
local ok, telescope = pcall(require, "telescope")
if not ok then
	print("Telescope not found in pack/ path!")
	return
end

local custom_ignore_pattern = { "node_modules", "build", "dist", ".git", ".venv", "__pycache__" }

telescope.setup({
	pickers = {
		find_files = {
			file_ignore_patterns = custom_ignore_pattern,
			hidden = true,
			no_ignore = true,
			cwd = vim.fn.getcwd(),
		},
	},
	live_grep = {
		file_ignore_patterns = custom_ignore_pattern,
		additional_args = function(_)
			return { "--hidden", "--no_ignore" }
		end,
	},
})

-- ==========================================================================
-- Keymaps
-- ==========================================================================
local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

vim.keymap.set("n", "<leader>sn", function()
	builtin.find_files({ cwd = vim.fn.stdpath("config") })
end, { desc = "[S]earch [N]eovim config files" })

-- show all Incomplete tasks
vim.keymap.set("n", "<leader>tt", function()
	builtin.grep_string({
		prompt_title = "Incomplete Tasks",
		search = "^\\s*- \\[ \\]",
		search_dirs = { vim.fn.getcwd() },
		use_regex = true,
	})
end, { desc = "[TT]asks" })

-- show all Complete tasks
vim.keymap.set("n", "<leader>tc", function()
	builtin.grep_string({
		prompt_title = "Complete Tasks",
		search = "^\\s*- \\[x\\]",
		search_dirs = { vim.fn.getcwd() },
		use_regex = true,
	})
end, { desc = "[T]asks [C]ompleted" })
