return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"andrew-george/telescope-themes",
		},
		config = function()

				local custom_ignore_pattern = { "node_modules", "build", "dist", ".git", ".venv" }
			require("telescope").setup({
				pickers = {
					find_files = {
						file_ignore_patterns = custom_ignore_pattern,
						hidden = true,
						no_ignore = true
					},
				},
				live_grep = {
					file_ignore_patterns = custom_ignore_pattern,
					additional_args = function(_)
						return { "--hidden", "--no_ignore" }
					end,
				},
				extenstions = {
					themes = {
						-- (boolean) -> show/hide previewer window
						enable_previewer = true,

						-- (boolean) -> enable/disable live preview
						enable_live_preview = false,

						persist = {
							-- enable persisting last theme choice
							enabled = true,

							-- override path to file that execute colorscheme command
							path = vim.fn.stdpath("config") .. "/lua/plugins/colorscheme.lua",
						},
					},
				},
			})
			local builtin = require("telescope.builtin")
			-- TODO: fix the keymaps
			vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
			vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
			vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
			vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
			vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
			vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
			vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
			vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
			vim.keymap.set("n", "<leader>st", "<cmd>TodoTelescope<cr>", { desc = "[S]earch [T]odo Comments" })
			vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })
			vim.keymap.set(
				"n",
				"<leader>ts",
				"<cmd>Telescope themes<CR>",
				{ noremap = true, silent = true, desc = "[T]heme [S]witcher" }
			)
			-- Shortcut for searching your Neovim configuration files
			vim.keymap.set("n", "<leader>sn", function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "[S]earch [N]eovim files" })
      
      -- show all Incomplete tasks
      vim.keymap.set("n", "<leader>tt", function()
        builtin.grep_string({
          prompt_title = "Incomplete Tasks",
          search = "^\\s*- \\[ \\]",
          search_dirs = {vim.fn.getcwd()},
          use_regex = true,
          additional_args = function()
            return { "--no-ignore" }
          end,
        })
      end, { desc = "[TT]asks" })

      -- show all Complete tasks
      vim.keymap.set("n", "<leader>tc", function()
        builtin.grep_string({
          prompt_title = "Complete Tasks",
          search = "^\\s*- \\[x\\]",
          search_dirs = {vim.fn.getcwd()},
          use_regex = true,
          additional_args = function()
            return { "--no-ignore" }
          end,
        })
      end, { desc = "[T]asks [C]ompleted" })



		end,
	},
}
