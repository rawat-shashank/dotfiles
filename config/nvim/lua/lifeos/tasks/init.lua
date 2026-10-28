-- ============================================================================
-- LifeOS Module (Tasks & Archiving)
-- ============================================================================
-- DOCUMENTATION & SPECIFICATION:
--
-- 1. Task Line Syntax & Format:
--    - Structure: `- [ ] (Priority) Description #tags @people ~(est) [due:: YYYY-MM-DD] [rec:: rule]`
--    - Checkbox States:
--        * `- [ ]` : Open / Pending
--        * `- [/]` : In Progress (Clocked In)
--        * `- [x]` : Completed (Clocked Out)
--        * `- [-]` : Cancelled / Archived
--
-- 2. Recurrence Rules ([rec:: ...], add manually):
--    - Relative Intervals : [rec:: +1d], [rec:: +1w], [rec:: +1m], [rec:: +1y]
--    - Specific Weekdays  : [rec:: mon], [rec:: mon,thu]
--    - Monthly Day        : [rec:: 15], [rec:: day:15] (Rolls over to the 15th of every month)
--    - Annual Date        : [rec:: 06-15], [rec:: yearly:06-15](Rolls over to June 15th every year)
--
-- 3. Commands & Lifecycle Flow:
--    - :LifeTasks         -> Opens the raw tasks.md file in the current window.
--    - :LifeTaskCapture   -> Interactive prompt to capture a new task with tags, priority, due date, etc.
--    - :LifeTasksPopup    -> Opens a floating window categorized by Overdue, Today, This Week, etc.
--    - :LifeClockIn       -> Marks task as In-Progress ([/]) and logs a start timestamp.
--    - :LifeClockOut      -> Marks task as Completed ([x]), closes timestamp, and automatically
--                            spawns the next instance in tasks.md if a [rec::] tag is present.
--    - :LifeTaskArchive   -> Moves all completed ([x]) or cancelled ([-]) task trees to archive.md.
-- ============================================================================

local M = {}

M.opts = {
	root_dir = vim.fn.expand("~/LifeOS"),
	actions_dir = vim.fn.expand("~/LifeOS/20-29_Actions/"),
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

--- Adds a recurrence interval to a given date string or current time
local function calculate_next_due(current_due_str, rec_rule)
	rec_rule = vim.trim(rec_rule:lower())

	-- 1. Check for specific day of the month (e.g., "15" or "day:15")
	local day_num = rec_rule:match("^%d+$") or rec_rule:match("^day:(%d+)$")
	if day_num then
		local target_day = tonumber(day_num)
		local t = os.date("*t", os.time())

		-- Move to next month
		t.month = t.month + 1
		t.day = target_day
		if t.month > 12 then
			t.month = 1
			t.year = t.year + 1
		end
		return os.date("%Y-%m-%d", os.time(t))
	end

	-- 2. Check for specific annual date (e.g., "06-15" or "yearly:06-15")
	local month_str, day_str = rec_rule:match("^(%d%d)-(%d%d)$") or rec_rule:match("yearly:(%d%d)-(%d%d)$")

	if month_str and day_str then
		local t = os.date("*t", os.time())
		t.month = tonumber(month_str)
		t.day = tonumber(day_str)

		-- If this date has already passed this year, push to next year
		if os.time(t) <= os.time() then
			t.year = t.year + 1
		end
		return os.date("%Y-%m-%d", os.time(t))
	end

	-- 3. (Other rules like weekdays, +1w, etc. fall through here...)
	if rec_rule:match("([a-z]+)") then
		-- Map day strings to numbers (1 = Sunday or Monday depending on setup)
		local target_days = {}
		for day in string.gmatch(rec_rule, "([^,%s]+)") do
			target_days[day] = true
		end

		local base_time = os.time() + 86400 -- Start checking from tomorrow
		for _ = 1, 14 do -- Look up to 2 weeks ahead to find the next matching day
			local t = os.date("*t", base_time)
			local wday_str = os.date("%a", base_time):lower() -- "mon", "tue", etc.

			if target_days[wday_str] then
				return os.date("%Y-%m-%d", base_time)
			end
			base_time = base_time + 86400
		end
	end

	-- 4. Fallback to your original relative offset parser (+1w, +2d, etc.)
	-- (Your existing sign/num/unit logic goes here)
	-- Match rule format: [rec:: +1w], [rec:: !1m], [rec:: 2d], etc.
	local sign, num_str, unit = rec_rule:match("([+!]?)(%d+)([dwmy])")
	if not num_str or not unit then
		return current_due_str
	end

	local num = tonumber(num_str)
	local base_time

	-- '+' = relative to today (completion date), '!' or blank = strict relative to old due date
	if sign == "+" then
		base_time = os.time()
	else
		base_time = parse_date(current_due_str) or os.time()
	end

	local t = os.date("*t", base_time)
	if unit == "d" then
		base_time = base_time + (num * 86400)
	elseif unit == "w" then
		base_time = base_time + (num * 7 * 86400)
	elseif unit == "m" then
		t.month = t.month + num
		base_time = os.time(t)
	elseif unit == "y" then
		t.year = t.year + num
		base_time = os.time(t)
	end

	return os.date("%Y-%m-%d", base_time)
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
					vim.ui.input({ prompt = "Due Date (YYYY-MM-DD) [Leave blank for 7 days]: " }, function(due)
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

							-- Add Estimate
							if est and est ~= "" then
								task_str = task_str .. string.format(" ~(%s)", est)
							end

							-- Due Date: Default to 7 days if blank, or use custom input
							if due and vim.trim(due) == "" then
								due = os.date("%Y-%m-%d", os.time() + 604800)
							end

							task_str = task_str .. string.format(" [due:: %s]", due)

							ensure_dirs(M.opts.root_dir)
							local file = io.open(M.opts.tasks_file, "a+")
							if file then
								file:write("\n" .. task_str)
								file:close()
								vim.notify("Captured: " .. task_str, vim.log.levels.INFO)
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

	-- local function list_tasks(completed, title)
	-- 	local buf, win = create_float(title)
	--
	-- 	-- Regex pattern to match open, in-progress, or completed tasks
	-- 	local task_str = completed and "^\\s*- \\[x\\]" or "^\\s*- \\[[ /]\\]"
	--
	-- 	local tasks_file = M.opts.tasks_file
	-- 	local archive_file = M.opts.archive_file
	--
	-- 	local cmd
	-- 	if vim.fn.executable("rg") == 1 then
	-- 		cmd = { "rg", "--line-number", "--no-heading", "--color=never", "-e", task_str, tasks_file }
	-- 	else
	-- 		cmd = {
	-- 			"grep",
	-- 			"-rnE",
	-- 			"--exclude-dir=.git",
	-- 			"--exclude-dir=node_modules",
	-- 			"-e",
	-- 			task_str,
	-- 			tasks_file,
	-- 			archive_file,
	-- 		}
	-- 	end
	--
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
						local due_str = content:match("@due%(%s*(%d%d%d%d%-%d%d%-%d%d)%s*%)")
							or content:match("%[due::%s*(%d%d%d%d%-%d%d%-%d%d)%]")
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
	list_tasks(false, "LifeOS Pending Tasks", M.opts.actions_dir)
end

-------------------------------------------------------------------------------
-- 2. TASK LIFECYCLE
-------------------------------------------------------------------------------

-- Helper to get current time and date
local function get_iso_time()
	return os.date("%Y-%m-%dT%H:%M:%S")
end

-- 1. CLOCK IN (<leader>ci)
function M.clock_in()
	local line = vim.api.nvim_get_current_line()

	if not line:match("%- %[[%s%w%/%-%?]%]") then
		vim.notify("No valid task checkbox found on line.", vim.log.levels.WARN)
		return
	end

	-- Switch checkbox state to In-Progress [/]
	line = line:gsub("%- %[ %]", "- [/]")
	line = line:gsub("%- %[x%]", "- [/]")
	line = line:gsub("%- %[%-%]", "- [/]")
	line = line:gsub("%- %[%?%]", "- [/]")

	-- Append Obsidian Clock In entry
	line = line .. string.format(" [clock::%s", get_iso_time())

	vim.api.nvim_set_current_line(line)
	vim.cmd("silent! update")
end

-- 2. CLOCK OUT (<leader>co) & RECURRENCE SPAWNER
function M.clock_out()
	local line = vim.api.nvim_get_current_line()
	local row = vim.api.nvim_win_get_cursor(0)[1]

	if not line:match("%- %[[%s%w%/%-%?]%]") then
		vim.notify("No valid task checkbox found on line.", vim.log.levels.WARN)
		return
	end

	-- 1. Extract recurrence rule before modifying the line (if any)
	local rec_rule = line:match("%[rec::%s*([^%]]+)%]")

	-- 2. Switch checkbox state to Complete [x]
	line = line:gsub("%- %[ %]", "- [x]")
	line = line:gsub("%- %[%/%]", "- [x]")
	line = line:gsub("%- %[%-%]", "- [x]")
	line = line:gsub("%- %[%?%]", "- [x]")

	-- 3. Complete the open clock tag
	if line:match("%[clock::[^%]]+$") or line:match("%[clock::[^%]]-%s*$") then
		line = line .. string.format("--%s]", get_iso_time())
	else
		line = line .. string.format(" [clock::%s]", get_iso_time())
	end

	vim.api.nvim_set_current_line(line)
	vim.cmd("silent! update")

	-- 4. If it's a recurring task, spawn the next instance
	if rec_rule then
		-- Extract current due date to calculate the next one
		local current_due = line:match("@due%(%s*(%d%d%d%d%-%d%d%-%d%d)%s*%)")
			or line:match("%[due::%s*(%d%d%d%d%-%d%d%-%d%d)%]")
			or os.date("%Y-%m-%d")

		local next_due = calculate_next_due(current_due, rec_rule)

		-- Build the new task line (reset to open checkbox [- [ ]], strip old clock logs)
		local new_task = line
		-- Reset checkbox
		new_task = new_task:gsub("%- %[x%]", "- [ ]")
		-- Remove old clock logs so the new instance starts fresh
		new_task = new_task:gsub("%s*%[clock::[^%]]+%]", "")

		-- Update the due date tag to the new future date
		if new_task:match("%[due::%s*%d%d%d%d%-%d%d%-%d%d%]") then
			new_task = new_task:gsub("%[due::%s*%d%d%d%d%-%d%d%-%d%d%]", string.format("[due:: %s]", next_due))
		else
			new_task = new_task .. string.format(" [due:: %s]", next_due)
		end

		-- Append the new task instance to tasks.md
		ensure_dirs(M.opts.root_dir)
		local file = io.open(M.opts.tasks_file, "a+")
		if file then
			file:write("\n" .. new_task)
			file:close()
			vim.notify("Recurring task spawned for: " .. next_due, vim.log.levels.INFO)
		end
		vim.cmd("silent! checktime")
		-- 5. Automatically Archive this completed task line
		local a_file = io.open(M.opts.archive_file, "a+")
		if a_file then
			a_file:write(string.format("\n## Archived on %s\n", os.date("%Y-%m-%d %H:%M")))
			a_file:write(line .. "\n")
			a_file:close()
		end

		-- 6. Remove the completed task from the current active tasks.md file buffer
		vim.api.nvim_buf_set_lines(0, row - 1, row, false, {})
		vim.cmd("silent! update")
	end
end

-- 2. CLOCK OUT (<leader>co)
-- function M.clock_out()
-- 	local line = vim.api.nvim_get_current_line()
--
-- 	if not line:match("%- %[[%s%w%/%-%?]%]") then
-- 		vim.notify("No valid task checkbox found on line.", vim.log.levels.WARN)
-- 		return
-- 	end
--
-- 	-- Switch checkbox state to Complete [x]
-- 	line = line:gsub("%- %[ %]", "- [x]")
-- 	line = line:gsub("%- %[%/%]", "- [x]")
-- 	line = line:gsub("%- %[%-%]", "- [x]")
-- 	line = line:gsub("%- %[%?%]", "- [x]")
--
-- 	-- Complete the open clock tag: change latest `[clock::...` to `[clock::...--timestamp]`
-- 	if line:match("%[clock::[^%]]+$") or line:match("%[clock::[^%]]-%s*$") then
-- 		line = line .. string.format("--%s]", get_iso_time())
-- 	else
-- 		-- Fallback: if user clocks out without a prior clock-in on this line
-- 		line = line .. string.format(" [clock::%s]", get_iso_time())
-- 	end
--
-- 	vim.api.nvim_set_current_line(line)
-- 	vim.cmd("silent! update")
-- end
--
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
	vim.api.nvim_create_user_command("LifeClockIn", M.clock_in, {})
	vim.api.nvim_create_user_command("LifeClockOut", M.clock_out, {})
	vim.api.nvim_create_user_command("LifeTaskArchive", M.archive_finished_tasks, {})
end

return M
