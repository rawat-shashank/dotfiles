-- Set leader key early so plugin setups bind correctly
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Need to load plugins first
require("plugins")

-- user related configs (options, keymaps, and autocmds)
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.statusline")
require("config.lsp")
require("config.diagnostic")

-- person plugins
require("lifeos")
