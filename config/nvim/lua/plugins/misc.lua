-- ==========================
-- vim-tmux-navigator
-- ==========================

vim.pack.add({ "https://github.com/christoomey/vim-tmux-navigator" })
vim.pack.add({ "https://github.com/echasnovski/mini.pairs" })

-- ==========================
-- folke/which-key
-- ==========================

vim.g.loaded_netrwPlugin = 1

-- Defer loading until after Neovim fully paints the screen
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		-- Load plugins lazily
		vim.pack.add({
			{ src = "https://github.com/folke/which-key.nvim" },
		})

		-- Setup yazi configs
		require("which-key").setup({
			preset = "helix",
		})

		-- Register Keymaps
		local map = vim.keymap.set
		map("n", "<leader>?", function()
			require("which-key").show({ loop = false })
		end, { desc = "(?) Buffer Local Keymaps (which-key)" })
	end,
})
