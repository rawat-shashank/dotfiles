-- ==========================
-- obsidian-nvim
-- ==========================

local root_dir = "~/LifeOS"

vim.pack.add({
	{ src = "https://github.com/obsidian-nvim/obsidian.nvim", load = false },
	{ src = "https://github.com/theboringhuman/obsidian-flashcards.nvim", load = false },
})

local opts = {
	workspaces = {
		{
			name = "personal",
			path = root_dir,
		},
	},
	notes_subdir = "10-19_Inbox_&_Journals/11_Inbox",
	new_notes_location = "notes_subdir",
	templates = {
		folder = "00-09_Support/02_Templates",
		date_format = "%Y-%m-%d",
		time_format = "%H:%M",
	},
	note = {
		template = vim.NIL,
	},
	daily_notes = {
		folder = "10-19_Inbox_&_Journals/12_Journal",
		date_format = "%Y/%m/%Y-%m-%d",
		template = "Daily_Template",
	},
	frontmatter = {
		enabled = true,
		func = function(note)
			local out = require("obsidian.builtin").frontmatter(note)

			local path_str = tostring(note.path or "")
			if path_str:match("12_Journal") then
				-- Dynamically inject the day property for daily notes
				-- out.day = os.date("%A")
				local filename = note.filename or vim.fs.basename(path_str)
				local y, m, d = filename:match("(%d%d%d%d)%-(%d%d)%-(%d%d)")

				if y and m and d then
					local file_time = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d) })
					out.day = os.date("%A", file_time)
				else
					-- Fallback to current system day if no date found in filename
					out.day = os.date("%A")
				end
			end

			return out
		end,
	},
	attachments = {
		folder = "00-09_Support/01_Assets",
		img_text_func = require("obsidian.builtin").img_text_func,
		img_name_func = function()
			return string.format("Pasted image %s", os.date("%Y%m%d%H%M%S"))
		end,
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
		return suffix
	end,

	checkbox = {
		order = { " ", "/", "x", "-", "?" },
	},
	picker = {
		name = "fzf-lua",
	},
}

local function load_and_setup_obsidian()
	-- Force Neovim to load the package files into the runtime path
	-- obsidian config and keymaps
	vim.cmd("packadd obsidian.nvim")

	local obsidian = require("obsidian")
	obsidian.setup(opts)
	vim.keymap.set("n", "<leader>dj", "<cmd>Obsidian today<cr>", {
		noremap = true,
		silent = true,
		desc = "[d]aily [j]ournal",
	})

	-- Notes keympas
	vim.keymap.set("n", "<leader>cn", function()
		vim.ui.input({ prompt = "Enter Note Title: " }, function(title)
			if not title or title == "" then
				return
			end
			-- Executes: :Obsidian new_from_template "Title" inbox-note
			vim.cmd(string.format('Obsidian new_from_template "%s" Atomic_Note', title))
		end)
	end, { desc = "LifeOS: [c]reate [n]ote with atomic Template" })

	vim.keymap.set("n", "<leader>cN", ":Obsidian new <CR>", { desc = "LifeOS: [c]reate [N]ote" })

	vim.keymap.set("n", "<leader>pi", function()
		vim.ui.input({ prompt = "Enter Image Title: " }, function(title)
			if not title or title == "" then
				return
			end
			-- Executes: :Obsidian new_from_template "Title" inbox-note
			vim.cmd(string.format("Obsidian paste_img %s", title))
		end)
	end, { desc = "LifeOS: [p]aste [i]mage" })

	-- Initialize task management and keymaps
	local tasks = require("lifeos.tasks")
	tasks.setup({ root_dir = vim.fn.expand(root_dir) })

	vim.keymap.set("n", "<leader>ct", tasks.capture_task, { desc = "[c]apture [t]ask", noremap = true, silent = true })
	vim.keymap.set(
		"n",
		"<leader>st",
		tasks.open_tasks_popup,
		{ desc = "[s]earch [t]tasks (FZF)", noremap = true, silent = true }
	)
	vim.keymap.set("n", "<leader>ci", tasks.clock_in, { desc = "[c]lock [i]n", noremap = true, silent = true })
	vim.keymap.set("n", "<leader>co", tasks.clock_out, { desc = "[c]lock [o]ut", noremap = true, silent = true })

	vim.keymap.set(
		"n",
		"<leader>ta",
		tasks.archive_finished_tasks,
		{ desc = "[t]ask [a]rchive", noremap = true, silent = true }
	)

	-- Initialize flashcards and keymaps
	vim.cmd("packadd obsidian-flashcards.nvim")

	vim.keymap.set("n", "<leader>fc", function()
		require("obsidian-flashcards").start()
	end, { desc = "[f]lash [c]ards", noremap = true, silent = true })

	-- Initialize macros
	require("lifeos.macros").setup()

	-- LifeOS Enhancements: Import FitNotes Natively
	require("lifeos.workout").setup({ root_dir = root_dir })
end

-- Replicates Lazy's lazyload `cond` and `cmd` parameters
-- only load when neovim open in obsidan root dir or tasks
local target_vault = vim.fn.expand(root_dir)

if vim.fn.getcwd() == target_vault then
	load_and_setup_obsidian()
else
	local obsidian_lazy_group = vim.api.nvim_create_augroup("LazyLoadObsidian", { clear = true })

	vim.api.nvim_create_autocmd("CmdUndefined", {
		group = obsidian_lazy_group,
		pattern = "Obsidian*",
		callback = function()
			load_and_setup_obsidian()
			vim.api.nvim_del_augroup_by_name("LazyLoadObsidian")
		end,
	})
end
