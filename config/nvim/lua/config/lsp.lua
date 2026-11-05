-- LSP Servers & Configs
local servers = { "bashls", "lua_ls", "ts_ls", "svelte" }

local server_settings = {
	lua_ls = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = vim.api.nvim_get_runtime_file("lua", true),
				checkThirdParty = false,
			},
			telemetry = {
				enable = false,
			},
		},
	},
	svelte = {
		svelte = {
			plugin = {
				svelte = {
					defaultScriptLanguage = "ts",
				},
			},
		},
	},
}

require("nvim-treesitter").setup({
	ensure_installed = { "lua", "javascript", "typescript", "svelte", "html" },
	auto_install = true,
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = { "svelte" },
	},
})

-- Capabilities setup via Blink.cmp
local base_capabilities = require("blink.cmp").get_lsp_capabilities()

-- Mason LSPConfig Bridge
require("mason-lspconfig").setup({
	ensure_installed = servers,
	automatic_installation = true,
})

-- Enable servers using Neovim 0.12 Native LSP API
for _, server in ipairs(servers) do
	local capabilities = vim.tbl_deep_extend("force", {}, base_capabilities)

	-- Server-specific adjustments (e.g., Svelte file watching workaround)
	if server == "svelte" then
		capabilities.workspace = capabilities.workspace or {}
		capabilities.workspace.didChangeWatchedFiles = false
	end

	-- Configure and enable natively
	vim.lsp.config(server, {
		capabilities = capabilities,
		settings = server_settings[server] or {},
	})
	vim.lsp.enable(server)
end
