-- ============================================================================
-- LifeOS Module (Tasks & Archiving)
-- ============================================================================

local M = {}

M.opts = {
	root_dir = vim.fn.expand("~/LifeOS"),
	tasks_file = vim.fn.expand("~/LifeOS/20-29_Actions/21_Tasks/tasks.md"),
	archive_file = vim.fn.expand("~/LifeOS/20-29_Actions/21_Tasks/archive.md"),
}

-------------------------------------------------------------------------------
-- HELPERS
-------------------------------------------------------------------------------

local function ensure_dirs(path)
	vim.fn.mkdir(path, "p")
end

local function get_indent_level(line)
	local indent = line:match("^(%s*)")
	return #indent
end

-------------------------------------------------------------------------------
-- 1. TASK CAPTURE & QUICK OPEN (FZF POPUP)
-------------------------------------------------------------------------------

-- Quick capture tasks with optional parent task, tags, and people
function M.capture_task()
	vim.ui.input({ prompt = "Task description: " }, function(desc)
		if not desc or desc == "" then
			return
		end

		vim.ui.input({ prompt = "Tags (comma-separated, e.g. dev,work) [Optional]: " }, function(tags)
			vim.ui.input({ prompt = "People (comma-separated, e.g. john,sarah) [Optional]: " }, function(people)
				vim.ui.input({ prompt = "Priority (A/B/C) [Optional]: " }, function(prio)
					vim.ui.input({ prompt = "Due Date (YYYY-MM-DD) [Optional]: " }, function(due)
						vim.ui.input({ prompt = "Estimate (e.g. 2h, 45m) [Optional]: " }, function(est)
							local task_str = "- [ ] "
							if prio and prio ~= "" then
								task_str = task_str .. "(" .. prio:upper() .. ") "
							end

							task_str = task_str .. desc

							-- Add tags (#tag)
							if tags and tags ~= "" then
								for tag in string.gmatch(tags, "([^,%s]+)") do
									task_str = task_str .. " #" .. tag
								end
							end

							-- Add people (@person)
							if people and people ~= "" then
								for person in string.gmatch(people, "([^,%s]+)") do
									task_str = task_str .. " @" .. person
								end
							end

							if est and est ~= "" then
								task_str = task_str .. string.format(" ~(%s)", est)
							end

							if due and due ~= "" then
								task_str = task_str .. string.format(" @due(%s)", due)
							end

							ensure_dirs(M.opts.root_dir)
							local file = io.open(M.opts.tasks_file, "a+")
							if file then
								file:write("\n" .. task_str)
								file:close()
								vim.notify("Captured task to " .. M.opts.tasks_file, vim.log.levels.INFO)
							end
						end)
					end)
				end)
			end)
		end)
	end)
end

--- Creates a centered floating window with manual folding
---@param title string The title of the window
---@return integer buf, integer win
local function create_float(title)
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	local buf = vim.api.nvim_create_buf(false, true)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " " .. title .. " ",
		title_pos = "center",
	})

	vim.wo[win].number = true
	vim.wo[win].relativenumber = true

	-- Enable folding support inside the float
	vim.wo[win].foldmethod = "manual"
	vim.wo[win].foldenable = true
	vim.wo[win].foldcolumn = "1"

	-- Quick exit mapping
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf, silent = true })
	vim.keymap.set("n", "<Esc>", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf, silent = true })

	return buf, win
end

--- Parses date strings (YYYY-MM-DD) into time seconds
local function parse_date(date_str)
	if not date_str then
		return nil
	end
	local y, m, d = date_str:match("(%d%d%d%d)%-(%d%d)%-(%d%d)")
	if y and m and d then
		return os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d) })
	end
	return nil
end

--- Searches for tasks and populates categorized floating window
---@param completed boolean Whether to search for completed tasks
---@param title string Title of the floating window
---@param root_dir string Directory path to search tasks in
local function list_tasks(completed, title, root_dir)
	local buf, win = create_float(title)

	-- Regex pattern to match open, in-progress, or completed tasks
	local task_str = completed and "^\\s*- \\[x\\]" or "^\\s*- \\[[ /]\\]"
	local base_dir = root_dir or vim.fn.getcwd():gsub("/+$", "")

	local cmd
	if vim.fn.executable("rg") == 1 then
		cmd = { "rg", "--line-number", "--no-heading", "--color=never", "-e", task_str, base_dir }
	else
		cmd = { "grep", "-rnE", "--exclude-dir=.git", "--exclude-dir=node_modules", "-e", task_str, base_dir }
	end

	vim.system(cmd, { text = true }, function(out)
		local in_progress_tasks = {}
		local overdue_tasks = {}
		local today_tasks = {}
		local week_tasks = {}
		local other_tasks = {}

		local today_start = os.time({
			year = os.date("%Y"),
			month = os.date("%m"),
			day = os.date("%d"),
			hour = 0,
			min = 0,
			sec = 0,
		})
		local today_end = today_start + 86399
		local week_end = today_start + (7 * 86400)

		if out.code == 0 and out.stdout ~= "" then
			for _, raw_line in ipairs(vim.split(out.stdout, "\n", { trimempty = true })) do
				local file, lnum, content = raw_line:match("^(.-):(%d+):(.*)$")
				if file and lnum and content then
					local clean_task = content:gsub("^%s*", ""):gsub("%s+$", "")

					local is_completed_task = content:match("^%s*- %[[]xX]%]") ~= nil
					local is_in_progress = content:match("^%s*- %[%/%]") ~= nil

					if (completed and is_completed_task) or (not completed and not is_completed_task) then
						local due_str = content:match("%[due::%s*(%d%d%d%d%-%d%d%-%d%d)%]")
							or content:match("📅%s*(%d%d%d%d%-%d%d%-%d%d)")

						local due_time = parse_date(due_str)
						local item = { file = file, lnum = tonumber(lnum), text = "  " .. clean_task }

						if is_in_progress then
							table.insert(in_progress_tasks, item)
						elseif due_time then
							if due_time < today_start and not completed then
								table.insert(overdue_tasks, item)
							elseif due_time <= today_end then
								table.insert(today_tasks, item)
							elseif due_time <= week_end then
								table.insert(week_tasks, item)
							else
								table.insert(other_tasks, item)
							end
						else
							table.insert(other_tasks, item)
						end
					end
				end
			end
		end

		vim.schedule(function()
			if not vim.api.nvim_buf_is_valid(buf) then
				return
			end

			local display_lines = {}
			local locations = {}
			local folds = {}

			local function append_section(header, tasks)
				local start_line = #display_lines + 1
				table.insert(display_lines, header .. " (" .. #tasks .. ")")
				table.insert(locations, false)

				for _, t in ipairs(tasks) do
					table.insert(display_lines, t.text)
					table.insert(locations, { file = t.file, lnum = t.lnum })
				end

				local end_line = #display_lines
				if #tasks > 0 then
					table.insert(folds, { start_line, end_line })
				end

				table.insert(display_lines, "")
				table.insert(locations, false)
			end

			append_section("▼ ⏱️ In Progress", in_progress_tasks)
			if not completed then
				append_section("▼ 🚨 Overdue", overdue_tasks)
			end
			append_section("▼ 📅 Today", today_tasks)
			append_section("▼ 🗓️ This Week", week_tasks)
			append_section("▼ 📥 Anything Else", other_tasks)

			vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)
			vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

			-- Create Folds and keep them OPEN initially
			vim.api.nvim_win_call(win, function()
				for _, fold in ipairs(folds) do
					vim.cmd(string.format("%d,%dfold", fold[1], fold[2]))
				end
				vim.cmd("normal! zR")
			end)

			-- Keymap to jump directly to task line on <CR>
			vim.keymap.set("n", "<CR>", function()
				local cursor_row = vim.api.nvim_win_get_cursor(win)[1]
				local target = locations[cursor_row]

				if target then
					vim.api.nvim_win_close(win, true)
					vim.cmd("edit " .. vim.fn.fnameescape(target.file))
					vim.api.nvim_win_set_cursor(0, { target.lnum, 0 })
				end
			end, { buffer = buf, noremap = true, silent = true, desc = "Jump to task" })
		end)
	end)
end

function M.open_tasks_popup()
	ensure_dirs(M.opts.root_dir)
	list_tasks(false, "LifeOS Tasks", M.opts.root_dir)
end

-------------------------------------------------------------------------------
-- 2. TASK LIFECYCLE
-------------------------------------------------------------------------------

function M.cycle_task_state()
	local buf = vim.api.nvim_get_current_buf()
	local line = vim.api.nvim_get_current_line()

	if not line:match("%- %[[%s%w%/%-%?]%]") then
		vim.notify("No valid task checkbox found on line.", vim.log.levels.WARN)
		return
	end

	local now_time = os.date("%H:%M")
	local now_date = os.date("%Y-%m-%d")

	-- State 1: Open [ ] -> Start [/]
	if line:match("%- %[ %]") then
		line = line:gsub("%- %[ %]", "- [/]")
		if not line:match("@started") then
			line = line .. string.format(" @started(%s)", now_time)
		end
		vim.api.nvim_set_current_line(line)

	-- State 2: In-Progress [/] -> Complete [x]
	elseif line:match("%- %[%/%]") then
		line = line:gsub("%- %[%/%]", "- [x]")
		if not line:match("@completed") then
			line = line .. string.format(" @completed(%s %s)", now_date, now_time)
		end
		vim.api.nvim_set_current_line(line)

	-- State 3: Complete [x] -> Cancelled [-]
	elseif line:match("%- %[x%]") then
		line = line:gsub("%- %[x%]", "- [-]")
		vim.api.nvim_set_current_line(line)

	-- State 4: Cancelled [-] -> Blocked [?]
	elseif line:match("%- %[%-%]") then
		line = line:gsub("%- %[%-%]", "- [?]")
		if not line:match("@waiting") then
			line = line .. " @waiting(blocker)"
		end
		vim.api.nvim_set_current_line(line)

	-- State 5: Blocked [?] -> Reset to Open [ ]
	elseif line:match("%- %[%?%]") then
		line = line:gsub("%- %[%?%]", "- [ ]")
		line = line:gsub("%s*@waiting%([^%)]+%)", "")
		vim.api.nvim_set_current_line(line)
	end
end

-------------------------------------------------------------------------------
-- 3. TASK ARCHIVING
-------------------------------------------------------------------------------

-- Move finished task trees ([x] or [-]) from the current buffer to Archive.md
function M.archive_finished_tasks()
	ensure_dirs(M.opts.root_dir)
	local buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	local keep_lines = {}
	local archive_lines = {}
	local archiving = false
	local current_indent = 0

	for _, line in ipairs(lines) do
		local is_task = line:match("%- %[[%s%w%/%-%?]%]")
		local indent = get_indent_level(line)

		if is_task then
			if line:match("%- %[x%]") or line:match("%- %[%-%]") then
				archiving = true
				current_indent = indent
				table.insert(archive_lines, line)
			elseif indent > current_indent and archiving then
				table.insert(archive_lines, line)
			else
				archiving = false
				table.insert(keep_lines, line)
			end
		elseif archiving and indent > current_indent then
			table.insert(archive_lines, line)
		else
			archiving = false
			table.insert(keep_lines, line)
		end
	end

	if #archive_lines == 0 then
		vim.notify("No completed/cancelled tasks to archive.", vim.log.levels.INFO)
		return
	end

	-- Write to Archive.md
	local a_file = io.open(M.opts.archive_file, "a+")
	if a_file then
		a_file:write(string.format("\n\n## Archived on %s\n", os.date("%Y-%m-%d %H:%M")))
		for _, l in ipairs(archive_lines) do
			a_file:write(l .. "\n")
		end
		a_file:close()
	end

	-- Update buffer
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, keep_lines)
	vim.notify(string.format("Archived %d lines to Archive.md", #archive_lines), vim.log.levels.INFO)
end

-------------------------------------------------------------------------------
-- SETUP & USER COMMANDS
-------------------------------------------------------------------------------

function M.open_tasks()
	ensure_dirs(M.opts.root_dir)
	vim.cmd("edit " .. vim.fn.fnameescape(M.opts.tasks_file))
end

function M.setup(user_opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, user_opts or {})

	vim.api.nvim_create_user_command("LifeTasks", M.open_tasks, {})
	vim.api.nvim_create_user_command("LifeTaskCapture", M.capture_task, {})
	vim.api.nvim_create_user_command("LifeTasksPopup", M.open_tasks_popup, {})
	vim.api.nvim_create_user_command("LifeTaskToggle", M.cycle_task_state, {})
	vim.api.nvim_create_user_command("LifeTaskArchive", M.archive_finished_tasks, {})
end

return M
