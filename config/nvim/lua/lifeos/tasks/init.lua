-- ============================================================================
-- LifeOS Module (Tasks & Archiving)
-- ============================================================================
-- DOCUMENTATION & SPECIFICATION:
--
-- 1. Task Line Syntax & Format:
--    - Structure: `- [ ] (Priority) Description #tags @people ~(est) [sched:: YYYY-MM-DD] [due:: YYYY-MM-DD] [rec:: rule]`
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
--    - :LifeTaskCapture   -> Interactive prompt to capture a new task with tags, priority, schedule, due date, etc.
--    - :LifeTasksPopup    -> Opens a floating window categorized by Overdue, Today, This Week, etc.
--    - :LifeClockIn       -> Marks task as In-Progress ([/]) and logs a start timestamp.
--    - :LifeClockOut      -> Marks task as Completed ([x]), closes timestamp, and automatically
--                            spawns the next instance in tasks.md if a [rec::] tag is present.
--    - :LifeTaskArchive   -> Moves all completed ([x]) or cancelled ([-]) task trees to archive.md.
-- ============================================================================

local M = {}
local config = require("lifeos.config")

M.opts = {
	root_dir = config.paths.expanded_root,
	actions_dir = config.paths.actions_dir,
	tasks_file = config.paths.tasks_file,
	archive_file = config.paths.archive_file,
}

-------------------------------------------------------------------------------
-- HELPERS
-------------------------------------------------------------------------------

--- Ensures that a directory path exists on disk, creating parent directories if needed.
--- @param path string Target directory path.
--- @return nil
local function ensure_dirs(path)
	vim.fn.mkdir(path, "p")
end

--- Calculates the leading indentation level (number of spaces) of a given line.
--- @param line string The target line string.
--- @return number indent Number of leading whitespace characters.
local function get_indent_level(line)
	local indent = line:match("^(%s*)")
	return #indent
end

--- Parses a date string (`YYYY-MM-DD`) into Unix time seconds.
--- @string? date_str Target date string to parse.
--- @return integer? timestamp Corresponding epoch time seconds, or nil on failure.
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

--- Calculates the next schedule date string based on an existing schedule date and recurrence rule.
--- @param current_sched_str string Current schedule date string (`YYYY-MM-DD`).
--- @param rec_rule string Recurrence rule configuration string.
--- @return string next_sched Calculated future schedule date string (`YYYY-MM-DD`).
local function calculate_next_schedule(current_sched_str, rec_rule)
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

	-- 3. Check for specific weekdays
	if rec_rule:match("([a-z]+)") then
		local target_days = {}
		for day in string.gmatch(rec_rule, "([^,%s]+)") do
			target_days[day] = true
		end

		local base_time = os.time() + 86400 -- Start checking from tomorrow
		for _ = 1, 14 do
			local t = os.date("*t", base_time)
			local wday_str = os.date("%a", base_time):lower()

			if target_days[wday_str] then
				return os.date("%Y-%m-%d", base_time)
			end
			base_time = base_time + 86400
		end
	end

	-- 4. Fallback to relative offset parser (+1w, +2d, etc.)
	local sign, num_str, unit = rec_rule:match("([+!]?)(%d+)([dwmy])")
	if not num_str or not unit then
		return current_sched_str
	end

	local num = tonumber(num_str)
	local base_time

	-- '+' = relative to today (completion date), '!' or blank = strict relative to old schedule date
	if sign == "+" then
		base_time = os.time()
	else
		base_time = parse_date(current_sched_str) or os.time()
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

local function get_tags_list()
	local tags = {}
	local seen = {}
	local f = io.open(M.opts.tasks_file, "r")
	if f then
		local content = f:read("*a")
		f:close()
		for tag in content:gmatch("#([%w_/-]+)") do
			if not seen[tag] then
				seen[tag] = true
				table.insert(tags, tag)
			end
		end
	end
	table.sort(tags)
	return tags
end

local function get_people_list()
	local people = {}
	local seen = {}
	local f = io.open(M.opts.tasks_file, "r")
	if f then
		local content = f:read("*a")
		f:close()
		for person in content:gmatch("@([%w_.-]+)") do
			if not seen[person] then
				seen[person] = true
				table.insert(people, person)
			end
		end
	end
	table.sort(people)
	return people
end

_G.lifeos_complete_tags = function(arglead, cmdline, cursorpos)
	local tags = get_tags_list()
	local last_word = arglead:match("[^,%s]+$") or arglead
	local matches = {}
	for _, tag in ipairs(tags) do
		if vim.startswith(tag, last_word) then
			table.insert(matches, tag)
		end
	end
	return #matches > 0 and matches or tags
end

_G.lifeos_complete_people = function(arglead, cmdline, cursorpos)
	local people = get_people_list()
	local last_word = arglead:match("[^,%s]+$") or arglead
	local matches = {}
	for _, person in ipairs(people) do
		if vim.startswith(person, last_word) then
			table.insert(matches, person)
		end
	end
	return #matches > 0 and matches or people
end

function M.capture_task()
	vim.ui.input({ prompt = "Task description: " }, function(desc)
		if not desc or desc == "" then
			return
		end

		vim.ui.input({
			prompt = "Tags (comma-separated, e.g. dev,work) [Optional]: ",
			completion = "customlist,v:lua.lifeos_complete_tags",
		}, function(tags)
			if not tags then
				return
			end
			vim.ui.input({
				prompt = "People (comma-separated, e.g. john,sarah) [Optional]: ",
				completion = "customlist,v:lua.lifeos_complete_people",
			}, function(people)
				if not people then
					return
				end
				vim.ui.input({ prompt = "Priority (A/B/C) [Optional]: " }, function(prio)
					if not prio then
						return
					end
					vim.ui.input({ prompt = "Schedule Date (YYYY-MM-DD) [Leave blank for Today]: " }, function(sched)
						if not sched then
							return
						end
						vim.ui.input(
							{ prompt = "Due Date (YYYY-MM-DD) [Leave blank for Schedule + 7 days]: " },
							function(due)
								if not due then
									return
								end
								vim.ui.input({ prompt = "Estimate (e.g. 2h, 45m) [Optional]: " }, function(est)
									if not est then
										return
									end
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

									-- Schedule Date: Default to Today if blank
									if not sched or vim.trim(sched) == "" then
										sched = os.date("%Y-%m-%d")
									end
									task_str = task_str .. string.format(" [sched:: %s]", sched)

									-- Due Date: Default to Schedule + 7 days if blank
									if not due or vim.trim(due) == "" then
										local sched_epoch = parse_date(sched) or os.time()
										due = os.date("%Y-%m-%d", sched_epoch + 604800)
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
							end
						)
					end)
				end)
			end)
		end)
	end)
end

--- Creates a centered floating window with manual folding and keymaps for exiting.
--- @param title string The title to display centered at the top of the float.
--- @return integer buf Created buffer handle.
--- @return integer win Created window handle.
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

	vim.wo[win].foldmethod = "manual"
	vim.wo[win].foldenable = true
	vim.wo[win].foldcolumn = "1"

	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf, silent = true })
	vim.keymap.set("n", "<Esc>", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf, silent = true })

	return buf, win
end

--- Searches for tasks and populates categorized floating window
---@param completed boolean Whether to search for completed tasks
---@param title string Title of the floating window
---@string? root_dir Optional root directory path to search within.
--- @return nil
local function list_tasks(completed, title, root_dir)
	local buf, win = create_float(title)

	local function parse_priority(content)
		local p = content:match("%-%s*%[[^%]]+%s*%(([%a])%)") or content:match("%(([A-Ca-c])%)")
		if p then
			p = p:upper()
			if p == "A" then
				return 1
			end
			if p == "B" then
				return 2
			end
			if p == "C" then
				return 3
			end
		end
		return 4
	end

	local function compare_tasks(a, b)
		if a.sched_time and b.sched_time then
			if a.sched_time ~= b.sched_time then
				return a.sched_time < b.sched_time
			end
		elseif a.sched_time and not b.sched_time then
			return true
		elseif not a.sched_time and b.sched_time then
			return false
		end

		if a.priority ~= b.priority then
			return a.priority < b.priority
		end

		if a.file ~= b.file then
			return a.file < b.file
		end
		return a.lnum < b.lnum
	end

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
						local sched_str = content:match("%[sched::%s*(%d%d%d%d%-%d%d%-%d%d)%]")
							or content:match("@sched%(%s*(%d%d%d%d%-%d%d%-%d%d)%s*%)")
							or content:match("%[due::%s*(%d%d%d%d%-%d%d%-%d%d)%]")
							or content:match("@due%(%s*(%d%d%d%d%-%d%d%-%d%d)%s*%)")

						local sched_time = parse_date(sched_str)
						local priority = parse_priority(content)
						local item = {
							file = file,
							lnum = tonumber(lnum),
							text = "  " .. clean_task,
							sched_time = sched_time,
							priority = priority,
						}

						if is_in_progress then
							table.insert(in_progress_tasks, item)
						elseif sched_time then
							if sched_time < today_start and not completed then
								table.insert(overdue_tasks, item)
							elseif sched_time <= today_end then
								table.insert(today_tasks, item)
							elseif sched_time <= week_end then
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

		table.sort(in_progress_tasks, compare_tasks)
		table.sort(overdue_tasks, compare_tasks)
		table.sort(today_tasks, compare_tasks)
		table.sort(week_tasks, compare_tasks)
		table.sort(other_tasks, compare_tasks)

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

			vim.api.nvim_win_call(win, function()
				for _, fold in ipairs(folds) do
					vim.cmd(string.format("%d,%dfold", fold[1], fold[2]))
				end
				vim.cmd("normal! zR")
			end)

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

local function get_iso_time()
	return os.date("%Y-%m-%dT%H:%M:%S")
end

function M.clock_in()
	local line = vim.api.nvim_get_current_line()

	if not line:match("%- %[[%s%w%/%-%?]%]") then
		vim.notify("No valid task checkbox found on line.", vim.log.levels.WARN)
		return
	end

	line = line:gsub("%- %[ %]", "- [/]")
	line = line:gsub("%- %[x%]", "- [/]")
	line = line:gsub("%- %[%-%]", "- [/]")
	line = line:gsub("%- %[%?%]", "- [/]")

	line = line .. string.format(" [clock::%s", get_iso_time())

	vim.api.nvim_set_current_line(line)
	vim.cmd("silent! update")
end

function M.clock_out()
	local line = vim.api.nvim_get_current_line()
	local row = vim.api.nvim_win_get_cursor(0)[1]

	if not line:match("%- %[[%s%w%/%-%?]%]") then
		vim.notify("No valid task checkbox found on line.", vim.log.levels.WARN)
		return
	end

	local rec_rule = line:match("%[rec::%s*([^%]]+)%]")

	line = line:gsub("%- %[ %]", "- [x]")
	line = line:gsub("%- %[%/%]", "- [x]")
	line = line:gsub("%- %[%-%]", "- [x]")
	line = line:gsub("%- %[%?%]", "- [x]")

	if line:match("%[clock::[^%]]+$") or line:match("%[clock::[^%]]-%s*$") then
		line = line .. string.format("--%s]", get_iso_time())
	else
		line = line .. string.format(" [clock::%s]", get_iso_time())
	end

	vim.api.nvim_set_current_line(line)
	vim.cmd("silent! update")

	if rec_rule then
		local current_sched = line:match("%[sched::%s*(%d%d%d%d%-%d%d%-%d%d)%]")
			or line:match("@sched%(%s*(%d%d%d%d%-%d%d%-%d%d)%s*%)")
			or os.date("%Y-%m-%d")

		local next_sched = calculate_next_schedule(current_sched, rec_rule)

		local new_task = line
		new_task = new_task:gsub("%- %[x%]", "- [ ]")
		new_task = new_task:gsub("%s*%[clock::[^%]]+%]", "")

		if new_task:match("%[sched::%s*%d%d%d%d%-%d%d%-%d%d%]") then
			new_task = new_task:gsub("%[sched::%s*%d%d%d%d%-%d%d%-%d%d%]", string.format("[sched:: %s]", next_sched))
		else
			new_task = new_task .. string.format(" [sched:: %s]", next_sched)
		end

		ensure_dirs(M.opts.root_dir)
		local file = io.open(M.opts.tasks_file, "a+")
		if file then
			file:write("\n" .. new_task)
			file:close()
			vim.notify("Recurring task scheduled for: " .. next_sched, vim.log.levels.INFO)
		end
		vim.cmd("silent! checktime")

		local a_file = io.open(M.opts.archive_file, "a+")
		if a_file then
			a_file:write(string.format("\n## Archived on %s\n", os.date("%Y-%m-%d %H:%M")))
			a_file:write(line .. "\n")
			a_file:close()
		end

		vim.api.nvim_buf_set_lines(0, row - 1, row, false, {})
		vim.cmd("silent! update")
	end
end

-------------------------------------------------------------------------------
-- 3. TASK ARCHIVING
-------------------------------------------------------------------------------

function M.archive_finished_tasks()
	ensure_dirs(M.opts.root_dir)
	local buf = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local cursor_row = cursor[1]
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	if #lines == 0 then
		vim.notify("Buffer is empty.", vim.log.levels.INFO)
		return
	end

	local task_blocks = {}
	for i = 1, #lines do
		local line = lines[i]
		local is_task = line:match("%- %[[%s%w%/%-%?]%]")
		if is_task then
			local indent = get_indent_level(line)
			local start_idx = i
			local end_idx = i

			for j = i + 1, #lines do
				local line_j = lines[j]
				local is_blank = line_j:match("^%s*$")
				local j_indent = get_indent_level(line_j)

				if is_blank then
					local has_subsequent_block_line = false
					for k = j + 1, #lines do
						local line_k = lines[k]
						if not line_k:match("^%s*$") then
							if get_indent_level(line_k) > indent then
								has_subsequent_block_line = true
							end
							break
						end
					end
					if has_subsequent_block_line then
						end_idx = j
					else
						break
					end
				elseif j_indent > indent then
					end_idx = j
				else
					break
				end
			end

			table.insert(task_blocks, {
				start_line = start_idx,
				end_line = end_idx,
			})
		end
	end

	local target_block = nil
	for _, block in ipairs(task_blocks) do
		if cursor_row >= block.start_line and cursor_row <= block.end_line then
			if not target_block or block.start_line > target_block.start_line then
				target_block = block
			end
		end
	end

	if not target_block then
		vim.notify("No task found under the cursor to archive.", vim.log.levels.INFO)
		return
	end

	local archive_lines = {}
	local keep_lines = {}

	for i, line in ipairs(lines) do
		if i >= target_block.start_line and i <= target_block.end_line then
			table.insert(archive_lines, line)
		else
			table.insert(keep_lines, line)
		end
	end

	if #archive_lines == 0 then
		vim.notify("No lines to archive.", vim.log.levels.INFO)
		return
	end

	local a_file = io.open(M.opts.archive_file, "a+")
	if a_file then
		a_file:write(string.format("\n\n## Archived on %s\n", os.date("%Y-%m-%d %H:%M")))
		for _, l in ipairs(archive_lines) do
			a_file:write(l .. "\n")
		end
		a_file:close()
	else
		vim.notify("Failed to open archive file: " + tostring(M.opts.archive_file), vim.log.levels.ERROR)
		return
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, keep_lines)

	local new_line_count = #keep_lines
	if new_line_count > 0 then
		local new_row = math.min(target_block.start_line, new_line_count)
		vim.api.nvim_win_set_cursor(0, { new_row, cursor[2] })
	end

	vim.notify(string.format("Archived task (%d lines) to Archive.md", #archive_lines), vim.log.levels.INFO)
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
