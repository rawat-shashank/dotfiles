local servers = {
	"lua_ls",
	"basedpyright",
	"ruff",
	-- Add more servers here, e.g., "pyright", "ts_ls"
}

local tools = {
	"stylua",
	"prettier",
	-- Add more formatters/linter here
}

return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			"saghen/blink.cmp",
		},
		config = function()
			-- 1. Setup Mason
			require("mason").setup()

			-- 2. Setup Mason Tool Installer (for formatters/linters)
			require("mason-tool-installer").setup({
				ensure_installed = tools,
			})

			-- 3. Setup Mason-LSPConfig (for language servers)
			local lspconfig = require("lspconfig")
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			require("mason-lspconfig").setup({
				ensure_installed = servers, -- This actually installs the servers
				handlers = {
					-- Default handler for all servers
					function(server_name)
						lspconfig[server_name].setup({
							capabilities = capabilities,
						})
					end,

					-- Specific handler for lua_ls
					["lua_ls"] = function()
						lspconfig.lua_ls.setup({
							capabilities = capabilities,
							settings = {
								Lua = {
									diagnostics = { globals = { "vim" } },
									completion = { callSnippet = "Replace" },
								},
							},
						})
					end,
				},
			})

			-- 4. Keymaps (LspAttach)
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					local opts = { buffer = ev.buf, silent = true }
					local keymap = vim.keymap

					opts.desc = "[G]oto [R]eferences"
					keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

					opts.desc = "[G]oto [D]efinition"
					keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

					opts.desc = "[G]oto [I]mplementations"
					keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

					opts.desc = "[C]ode [A]ctions"
					keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

					opts.desc = "[C]ode [r]ename"
					keymap.set("n", "<leader>cr", vim.lsp.buf.rename, opts)

					opts.desc = "Show documentation"
					keymap.set("n", "K", vim.lsp.buf.hover, opts)

					opts.desc = "Open Diagnostic float"
					keymap.set("n", "<leader>od", vim.diagnostic.open_float, opts)
				end,
			})
		end,
	},
}
