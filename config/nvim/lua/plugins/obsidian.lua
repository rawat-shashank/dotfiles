return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	ft = "markdown",
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
		legacy_commands = false,
	},
}
