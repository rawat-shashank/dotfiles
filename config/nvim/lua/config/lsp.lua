-- LSP Servers & Configs
local servers = { "bashls", "lua_ls" }

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
}

-- Capabilities setup via Blink.cmp
local capabilities = require("blink.cmp").get_lsp_capabilities()

-- Mason LSPConfig Bridge
require("mason-lspconfig").setup({
	ensure_installed = servers,
	automatic_installation = true,
})

-- Enable servers using Neovim 0.12 Native LSP API
for _, server in ipairs(servers) do
	vim.lsp.config[server] = {
		capabilities = capabilities,
		settings = server_settings[server] or {},
	}
	vim.lsp.enable(server)
end
