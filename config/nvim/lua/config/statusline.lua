-- Helper function to fetch highlight values directly from Neovim
local function get_hl(name)
	return vim.api.nvim_get_hl(0, { name = name, link = false })
end

-- Define highlight groups dynamically based on the active theme
local function setup_statusline_hls()
	local stl = get_hl("StatusLine")
	local pms = get_hl("PmenuSel")
	local dir = get_hl("Directory")
	local fn = get_hl("Function")
	local str = get_hl("String")
	local special = get_hl("Special")
	local linenr = get_hl("LineNr")
	local comment = get_hl("Comment")
	local err = get_hl("Error")
	local warn = get_hl("WarningMsg")

	-- Background base from current StatusLine
	local bg_base = stl.bg or pms.bg

	-- Mode highlight groups
	vim.api.nvim_set_hl(0, "StlModeNormal", { fg = bg_base, bg = dir.fg or pms.fg, bold = true })
	vim.api.nvim_set_hl(0, "StlModeInsert", { fg = bg_base, bg = fn.fg, bold = true })
	vim.api.nvim_set_hl(0, "StlModeVisual", { fg = bg_base, bg = str.fg, bold = true })
	vim.api.nvim_set_hl(0, "StlModeReplace", { fg = bg_base, bg = err.fg, bold = true })
	vim.api.nvim_set_hl(0, "StlModeCommand", { fg = bg_base, bg = warn.fg, bold = true })

	-- Section highlights
	vim.api.nvim_set_hl(0, "StlGit", { fg = dir.fg, bg = bg_base, bold = true })

	-- Path Breadcrumb Highlights
	vim.api.nvim_set_hl(0, "StlProject", { fg = fn.fg, bg = bg_base, bold = true })
	vim.api.nvim_set_hl(0, "StlSep", { fg = comment.fg, bg = bg_base })
	vim.api.nvim_set_hl(0, "StlPath", { fg = stl.fg, bg = bg_base })

	-- Filetype text highlight
	vim.api.nvim_set_hl(0, "StlFtName", { fg = special.fg, bg = bg_base })
	vim.api.nvim_set_hl(0, "StlPosition", { fg = linenr.fg, bg = bg_base })
end

-- Initialize highlights and reload them whenever colorscheme changes
setup_statusline_hls()
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = setup_statusline_hls,
})

-- Mode mapping with corresponding highlight groups
local mode_map = {
	n = { name = "NORMAL", hl = "%#StlModeNormal#" },
	i = { name = "INSERT", hl = "%#StlModeInsert#" },
	v = { name = "VISUAL", hl = "%#StlModeVisual#" },
	V = { name = "V-LINE", hl = "%#StlModeVisual#" },
	["\22"] = { name = "V-BLOCK", hl = "%#StlModeVisual#" },
	c = { name = "COMMAND", hl = "%#StlModeCommand#" },
	t = { name = "TERMINAL", hl = "%#StlModeInsert#" },
	R = { name = "REPLACE", hl = "%#StlModeReplace#" },
	s = { name = "SELECT", hl = "%#StlModeVisual#" },
	S = { name = "S-LINE", hl = "%#StlModeVisual#" },
	["\19"] = { name = "S-BLOCK", hl = "%#StlModeVisual#" },
}

-- Fetch icon and its native highlight group directly from mini.icons
local function get_file_icon()
	local ft = vim.bo.filetype
	local file_name = vim.fn.expand("%:t")

	-- Fallback if mini.icons isn't loaded
	if not _G.MiniIcons then
		return "%#StlPath#\u{f15b}%*"
	end

	local icon, hl
	if ft ~= "" then
		icon, hl = MiniIcons.get("filetype", ft)
	else
		icon, hl = MiniIcons.get("file", file_name)
	end

	return "%#" .. (hl or "StlPath") .. "#" .. icon .. "%*"
end

-- Constructs [project] > immediate_parent/<icon> filename.ext
local function compact_path()
	local project_name = vim.b.git_root_name
	if not project_name then
		local cwd = vim.fn.getcwd()
		project_name = vim.fn.fnamemodify(cwd, ":t")
	end

	local file_name = vim.fn.expand("%:t")
	local icon = get_file_icon()

	if file_name == "" then
		return "%#StlProject# [" .. project_name .. "]%*"
	end

	local parent_dir = vim.fn.expand("%:p:h:t")

	local path_str
	if parent_dir == "" or parent_dir == project_name then
		path_str = "%#StlPath#" .. file_name .. "%*"
	else
		path_str = "%#StlPath#" .. parent_dir .. "/%*" .. "%#StlPath#" .. file_name .. "%*"
	end

	return "%#StlProject# [" .. project_name .. "]%* %#StlSep#> " .. icon .. " %#StlPath#" .. path_str .. "%*"
end

function _G._statusline()
	local current_mode = mode_map[vim.fn.mode()] or { name = vim.fn.mode():upper(), hl = "%#StlModeNormal#" }

	local mode_str = current_mode.hl .. " " .. current_mode.name .. " %*"
	local branch = vim.b.git_branch and "%#StlGit#  " .. vim.b.git_branch .. "%*" or ""
	local path = compact_path()

	local diag = ""
	local counts = vim.diagnostic.count(0) or {}
	local labels = { " ", " ", " ", " " }
	local hls = { "DiagnosticError", "DiagnosticWarn", "DiagnosticInfo", "DiagnosticHint" }
	for i = 1, 4 do
		if counts[i] and counts[i] > 0 then
			diag = diag .. "%#" .. hls[i] .. "#" .. labels[i] .. counts[i] .. "%* "
		end
	end

	local ft_str = "%#StlFtName#" .. (vim.bo.filetype ~= "" and vim.bo.filetype or "no ft") .. "%* "
	local position = "%#StlPosition#%l:%c %*"

	return mode_str .. branch .. path .. "%=" .. diag .. ft_str .. position
end

vim.api.nvim_create_autocmd("BufEnter", {
	callback = function()
		local root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("%s+$", "")
		if root ~= "" then
			vim.b.git_branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("%s+$", "")
			vim.b.git_root_name = vim.fn.fnamemodify(root, ":t")
		else
			vim.b.git_branch = nil
			vim.b.git_root_name = nil
		end
	end,
})

vim.api.nvim_create_autocmd("DiagnosticChanged", {
	callback = function()
		vim.cmd("redrawstatus!")
	end,
})

vim.o.statusline = "%!v:lua._statusline()"
