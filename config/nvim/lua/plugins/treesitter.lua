vim.pack.add({
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter",
		version = "main",
	},
})

require("nvim-treesitter").install({
	"lua",
	"python",
})

local SKIP_FT = { qf = true, help = true, minimized = true }

vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		local ft = vim.bo.filetype
		if SKIP_FT[ft] then
			return
		end

		local ok = pcall(vim.treesitter.start)
		if not ok then
			return
		end

		-- Only set expr folds when treesitter successfully started
		vim.wo.foldmethod = "expr"
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	end,
})
