-- ============================================================================
-- LifeOS Module: Central Configuration & Paths
-- ============================================================================
local M = {}

-- Define your base vault root path once here
local root_dir = "~/LifeOS"
local expanded_root = vim.fn.expand(root_dir)

M.paths = {
	root_dir = root_dir,
	expanded_root = expanded_root,

	-- Vault-Relative Paths (Required by obsidian.nvim)
	inbox_folder = "10-19_Inbox_&_Journals/11_Inbox",
	journal_folder = "/10-19_Inbox_&_Journals/12_Journal",
	assets_folder = "00-09_Support/01_Assets",
	templates_folder = "00-09_Support/02_Templates",

	-- Sub-directories
	actions_dir = expanded_root .. "/20-29_Actions/",

	-- Specific Files
	tasks_file = expanded_root .. "/20-29_Actions/21_Tasks/tasks.md",
	archive_file = expanded_root .. "/20-29_Actions/21_Tasks/archive.md",
}

return M
