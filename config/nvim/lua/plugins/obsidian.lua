return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	cond = function()
		-- Replace with the absolute path to your vault
		return vim.fn.getcwd() == vim.fn.expand("~/obsidian/docs")
	end,
	keys = {
		{ "<leader>dn", "<cmd>Obsidian today<cr>", noremap = true, silent = true, desc = "[D]aily [N]otes" },
	},
	---@module 'obsidian'
	---@type obsidian.config
	opts = {
		workspaces = {
			{
				name = "personal",
				path = "~/obsidian/docs/",
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
		-- remove legacy_commands support
		legacy_commands = false,

		-- Optional, customize how note IDs are generated given an optional title.
		---@param title string|?
		---@return string
		note_id_func = function(title)
			-- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
			-- In this case a note with the title 'My new note' will be given an ID that looks
			-- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
			local suffix = ""
			if title ~= nil then
				-- If title is given, transform it into valid file name.
				suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
			else
				-- If title is nil, just add 4 random uppercase letters to the suffix.
				for _ = 1, 4 do
					suffix = suffix .. string.char(math.random(65, 90))
				end
			end
			return tostring(os.time()) .. "-" .. suffix
		end,
	},
}
