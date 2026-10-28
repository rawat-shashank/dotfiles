local opt = vim.opt

-- Neovim 0.12 Flags
vim.g.ui2 = true -- Enable experimental UI engine

-- Line numbers & layout
opt.number = true
opt.relativenumber = true
opt.wrap = false
opt.cursorline = true
opt.winborder = "rounded"
opt.signcolumn = "yes"
opt.colorcolumn = "80,120"
opt.scrolloff = 10
opt.showmatch = true
opt.conceallevel = 2

-- Tabs & indentation
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

-- Search settings
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- GUI & Appearance
opt.termguicolors = true

-- Backups & Undo
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.autochdir = false

-- Clipboard & Mouse
opt.mouse = "a"
opt.clipboard = "unnamedplus"

-- Spellcheck
opt.spell = true

-- ============================================================================
-- GLOBAL FOLDING CONFIGURATION
-- ============================================================================

-- Enable fold column (shows fold indicators and vertical connecting lines)
vim.opt.foldcolumn = "1"
vim.opt.foldenable = true
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99 -- 0 for all fold and 99 for all open
opt.smoothscroll = true
opt.foldminlines = 1

-- Set global fold symbols & vertical connecting line
vim.opt.fillchars:append({
	fold = " ", -- Fill remaining space on folded lines with blank spaces
	foldopen = "", -- Icon when fold is open
	foldclose = "", -- Icon when fold is closed
	foldsep = "│", -- Vertical side line connecting open fold levels
})

-- Custom fold text function to format closed fold lines cleanly
function _G.custom_fold_text()
	local line = vim.fn.getline(vim.v.foldstart)
	local line_count = vim.v.foldend - vim.v.foldstart + 1

	line = line:gsub("\t", string.rep(" ", vim.opt.tabstop:get()))

	return {
		{ line, "Normal" }, -- Main line in normal color
		{ " ... (" .. line_count .. " lines) ", "NonText" }, -- Muted text color check :highlight text
	}
end

vim.opt.foldtext = "v:lua.custom_fold_text()"
-- remove bg hightlight from folds
vim.api.nvim_set_hl(0, "Folded", { bg = "NONE" })
