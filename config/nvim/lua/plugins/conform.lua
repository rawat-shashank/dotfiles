vim.pack.add({ "https://github.com/stevearc/conform.nvim" })
local stylua = vim.fn.expand("~/.local/share/nvim/mason/bin/stylua")
local ruff_path = vim.fn.expand("~/.local/share/nvim/mason/bin/ruff")

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "ruff" },
	},
	formatters = {
		stylua = {
			command = stylua,
		},
		ruff = {
			command = ruff_path,
			args = { "format", "--stdin-filename", "$FILENAME", "-" },
		},
	},
	default_format_opts = { lsp_format = "fallback" },

	format_on_save = function(bufnr)
		local ignore_filetypes = { "sql" }
		if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
			return
		end
		if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
			return
		end
		if vim.api.nvim_buf_get_name(bufnr):match("/node_modules/") then
			return
		end
		return { timeout_ms = 500, lsp_format = "fallback" }
	end,
})

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
	require("conform").format({ async = true }, function(err, did_edit)
		if not err and did_edit then
			vim.notify("Code formatted", vim.log.levels.INFO, { title = "Conform" })
		end
	end)
end, { desc = "[C]ode [F]ormat" })
