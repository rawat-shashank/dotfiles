vim.g.loaded_netrwPlugin = 1

-- Defer loading until after Neovim fully paints the screen
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		-- Load plugins lazily
		vim.pack.add({
			{ src = "https://github.com/nvim-lua/plenary.nvim" },
			{ src = "https://github.com/mikavilpas/yazi.nvim" },
		})

		-- Setup yazi configs
		require("yazi").setup({
			open_for_directories = true,
			keymaps = { show_help = "<f1>" },
		})

		-- Register Keymaps
		local map = vim.keymap.set
		map({ "n", "v" }, "\\", "<cmd>Yazi<cr>", { desc = "Open yazi" })
		map("n", "<leader>cw", "<cmd>Yazi cwd<cr>", { desc = "Yazi in CWD" })
		map("n", "<c-up>", "<cmd>Yazi toggle<cr>", { desc = "Resume last yazi" })
	end,
})
