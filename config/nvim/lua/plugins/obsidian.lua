-- ==========================
-- obsidian-nvim
-- ==========================

local vault_path = "~/dev/obsidian/docs"

vim.pack.add({
	{ src = "https://github.com/obsidian-nvim/obsidian.nvim", load = false },
	{ src = "https://github.com/theboringhuman/obsidian-flashcards.nvim", load = false },
})

local opts = {
	workspaces = {
		{
			name = "personal",
			path = vault_path,
		},
	},
	notes_subdir = "100 Inbox",
	new_notes_location = "notes_subdir",
	completion = { blink = true, min_chars = 2 },
	templates = {
		folder = "400 Obsidian/403 Templates",
		date_format = "%Y-%m-%d",
		time_format = "%H:%M",
	},
	daily_notes = {
		folder = "500 Journal",
		date_format = "%Y/%m/%Y-%m-%d",
		template = "Daily Template",
	},
	footer = {
		enabled = true,
		format = "{{backlinks}} backlinks  {{properties}} properties  {{words}} words  {{chars}} chars",
		hl_group = "Comment",
		separator = string.rep("-", 80),
	},
	legacy_commands = false,
	note_id_func = function(title)
		local suffix = ""
		if title ~= nil then
			suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
		else
			for _ = 1, 4 do
				suffix = suffix .. string.char(math.random(65, 90))
			end
		end
		return tostring(os.time()) .. "-" .. suffix
	end,
	checkbox = {
		order = { " ", "x", "-" },
	},
}

local function load_and_setup_obsidian()
	-- Force Neovim to load the package files into the runtime path
	vim.cmd("packadd obsidian.nvim")

	local obsidian = require("obsidian")
	obsidian.setup(opts)

	vim.keymap.set("n", "<leader>dn", "<cmd>Obsidian today<cr>", {
		noremap = true,
		silent = true,
		desc = "[D]aily [N]otes",
	})

	vim.cmd("packadd obsidian-flashcards.nvim")

	vim.keymap.set("n", "<leader>fc", function()
		require("obsidian-flashcards").start()
	end, { desc = "Start Obsidian Flashcards", noremap = true, silent = true })
end

-- 4. Replicates lazy's `cond` and `cmd` parameters
local target_vault = vim.fn.expand(vault_path)

if vim.fn.getcwd() == target_vault then
	-- Condition passes: Load immediately
	load_and_setup_obsidian()
else
	-- Condition fails: Don't load yet. Instead, catch whenever the user types
	-- any command starting with ":Obsidian" and load it on-demand.
	local obsidian_lazy_group = vim.api.nvim_create_augroup("LazyLoadObsidian", { clear = true })

	vim.api.nvim_create_autocmd("CmdUndefined", {
		group = obsidian_lazy_group,
		pattern = "Obsidian*",
		callback = function()
			load_and_setup_obsidian()
			-- Delete the listener group so it doesn't try to reload on future commands
			vim.api.nvim_del_augroup_by_name("LazyLoadObsidian")
		end,
	})
end
