local M = {}

-- CONFIGURATION: Change this to your actual vault path
local vault_path = "~/dev/obsidian/docs"

local function create_window()
	local stats = vim.api.nvim_list_uis()[1]
	local width = math.floor(stats.width * 0.6)
	local height = math.floor(stats.height * 0.4)

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((stats.width - width) / 2),
		row = math.floor((stats.height - height) / 2),
		style = "minimal",
		border = "rounded",
		title = " Obsidian Flashcards ",
		title_pos = "center",
	})

	return buf, win
end

M.start = function()
	local cmd = string.format("rg --vimgrep '>\\s*\\[!question\\]-' %s", vault_path)
	local handle = io.popen(cmd)
	if not handle then
		return
	end
	local result = handle:read("*a")
	handle:close()

	local cards = {}
	for line in result:gmatch("[^\r\n]+") do
		local file, lnum, col, text = line:match("([^:]+):(%d+):(%d+):(.+)")

		if file and lnum then
			-- 2. Read the file to get the Question and the Answer (Next Line)
			local f = io.open(file, "r")
			if f then
				local lines = {}
				for l in f:lines() do
					table.insert(lines, l)
				end
				f:close()

				local line_num = tonumber(lnum)
				-- The 'front' is the text after the callout header on the same line
				local front = text:match(">%s*%[!question%]%-%s*(.*)")
				-- The 'back' is the line immediately following it, stripped of the '>'
				local back_raw = lines[line_num + 1]

				if front and back_raw then
					local back = back_raw:match(">%s*(.*)")
					table.insert(cards, {
						file = file,
						line = lnum,
						front = vim.trim(front),
						back = vim.trim(back or "No answer found"),
					})
				end
			end
		end
	end
	if #cards == 0 then
		print("No flashcards found with '::' in " .. vault_path)
		return
	end

	-- Shuffle cards
	math.randomseed(os.time())
	for i = #cards, 2, -1 do
		local j = math.random(i)
		cards[i], cards[j] = cards[j], cards[i]
	end

	-- 2. UI State
	local idx = 1
	local showing_answer = false
	local buf, win = create_window()

	local function render()
		local card = cards[idx]
		local content = { "Question:", "", "  " .. card.front, "" }
		if showing_answer then
			table.insert(content, "Answer:")
			table.insert(content, "")
			table.insert(content, "  " .. card.back)
			table.insert(content, "")
			table.insert(content, string.format(" (%d/%d) [Enter] Next  [g] Go to File", idx, #cards))
		else
			table.insert(content, " [Space] Reveal Answer")
		end

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
	end

	-- 3. Internal Keymaps for the Flashcard Window
	local opts = { buffer = buf, noremap = true, silent = true }

	-- Space to reveal
	vim.keymap.set("n", "<space>", function()
		showing_answer = true
		render()
	end, opts)

	-- Enter for Next Card
	vim.keymap.set("n", "<CR>", function()
		if idx < #cards then
			idx = idx + 1
			showing_answer = false
			render()
		else
			vim.api.nvim_win_close(win, true)
			print("Finished session!")
		end
	end, opts)

	-- 'g' to jump to source file
	vim.keymap.set("n", "g", function()
		local card = cards[idx]
		vim.api.nvim_win_close(win, true)
		vim.cmd("edit " .. card.file)
		vim.api.nvim_win_set_cursor(0, { tonumber(card.line), 0 })
	end, opts)

	-- 'q' to quit
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
	end, opts)

	render()
end

-- 4. GLOBAL KEYMAP to trigger the plugin
-- This allows you to call it from anywhere
vim.keymap.set("n", "<leader>fc", M.start, { desc = "Start Obsidian Flashcards" })

return M
