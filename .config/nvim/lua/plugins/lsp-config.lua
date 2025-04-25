local servers = {
	"lua_ls",
	"pyright",
	"ts_ls",
	"jsonls",
	"bashls",
}

local tools = {
	"stylua",
	"isort",
	"black",
	"pylint",
	"prettier",
	"eslint_d",
}

return {
	{
		"williamboman/mason.nvim",
		-- dependencies = {
		-- 	"williamboman/mason-lspconfig.nvim",
		-- 	"WhoIsSethDaniel/mason-tool-installer.nvim",
		-- },
		config = function()
			require("mason").setup({})
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = servers,
			})
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = tools,
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "saghen/blink.cmp" },
		},
		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local mason_lspconfig = require("mason-lspconfig")
			mason_lspconfig.setup_handlers({
				function(server_name)
					lspconfig[server_name].setup({
						capabilities = capabilities,
					})
				end,
				["lua_ls"] = function()
					-- configure lua server (with special settings)
					lspconfig["lua_ls"].setup({
						capabilities = capabilities,
						settings = {
							Lua = {
								-- make the language server recognize "vim" global
								diagnostics = {
									globals = { "vim" },
								},
								completion = {
									callSnippet = "Replace",
								},
							},
						},
					})
				end,
			})
			local keymap = vim.keymap
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					-- Buffer local mappings.
					-- See `:help vim.lsp.*` for documentation on any of the below functions
					local opts = { buffer = ev.buf, silent = true }

					-- set keybinds
					opts.desc = "[G]oto [R]efernces"
					keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)
					opts.desc = "[C]ode [r]ename"
					keymap.set("n", "<leader>cr", vim.lsp.buf.rename, opts)
					opts.desc = "[G]oto [D]efinition"
					keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
					opts.desc = "[G]oto [I]mplementations"
					keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
					opts.desc = "[C]ode [A]ctions"
					keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
					opts.desc = "[R]estart LSP"
					keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
					opts.desc = "Show documentation for what is under cursor"
					keymap.set("n", "K", vim.lsp.buf.hover, opts)
				end,
			})
		end,
	},
}
