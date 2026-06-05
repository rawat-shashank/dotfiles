-- Ensure ruff is installed via Mason or your system package manager
local custom_binary_path = vim.fn.expand("~/.local/share/nvim/mason/bin/ruff")

---@type vim.lsp.Config
return {
	-- 1. Use the absolute path to your Mason Ruff binary
	-- 2. Add the "server" argument so Ruff runs as a background language server
	cmd = { custom_binary_path, "server" },
	filetypes = { "python" },
	root_markers = { "pyproject.toml", "ruff.toml", ".git" },
	settings = {
		-- Ruff configuration properties go here
		ruff = {
			-- If you are already using conform.nvim for formatting,
			-- you can disable Ruff's built-in LSP formatting capabilities here
			format = {
				enable = false,
			},
			-- Enable or disable hover documentation documentation
			hover = {
				enable = true,
			},
		},
	},
}
