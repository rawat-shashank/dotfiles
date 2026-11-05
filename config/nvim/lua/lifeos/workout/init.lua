-- ============================================================================
-- LifeOS Module: FitNotes Workout Importer
-- ============================================================================
-- DOCUMENTATION & SPECIFICATION:
--
-- 1. Overview & Functionality:
--    - Parses FitNotes export text from the system clipboard.
--    - Automatically extracts workout dates from headers and identifies bodyweight exercises.
--    - Calculates total workout volume and updates/creates Markdown journal entries
--      within the structured LifeOS vault path (`YYYY/MM/YYYY-MM-DD.md`).
--
-- 2. Features:
--    - Frontmatter management (maintains fields and updates metadata/workout volume).
--    - Interactive routine selection picker via `vim.ui.select`.
--    - Automatically opens the generated or updated journal file in Neovim.
--
-- 3. Commands & Keymaps:
--    - <leader>fn -> Imports FitNotes data from the system clipboard, prompts for routine category,
--                    and opens the target daily journal file.
-- ============================================================================

local M = {}
local config = require("lifeos.config")

local BODYWEIGHT_KEYWORDS = {
	"hanging knee raise",
	"pull up",
	"chin up",
	"dip",
	"push up",
	"crunch",
	"knee raise",
	"leg raise",
	"bodyweight",
}

local MONTHS = {
	January = 1,
	February = 2,
	March = 3,
	April = 4,
	May = 5,
	June = 6,
	July = 7,
	August = 8,
	September = 9,
	October = 10,
	November = 11,
	December = 12,
}

--- Parses the workout date from the FitNotes header line.
--- Cleans non-standard characters and ordinal suffixes, matching day, month, and year.
--- Falls back to the current system date if parsing fails.
--- @param header_line string The raw header line string from the FitNotes export.
--- @return string date_str Formatted date string (`YYYY-MM-DD`).
--- @return string year_str Formatted year string (`YYYY`).
--- @return string month_str Formatted month string (`MM`).
local function parse_date_from_header(header_line)
	local clean_line = header_line:gsub("\194\160", " ")
	clean_line = clean_line:gsub("(%d+)st", "%1"):gsub("(%d+)nd", "%1"):gsub("(%d+)rd", "%1"):gsub("(%d+)th", "%1")
	local day, month_name, year = clean_line:match("(%d%d?)%s+([A-Za-z]+)%s+(%d%d%d%d)")

	if day and month_name and year then
		month_name = month_name:sub(1, 1):upper() .. month_name:sub(2):lower()
		local m = MONTHS[month_name]
		if m then
			local d_num = tonumber(day)
			local y_num = tonumber(year)
			local date_str = string.format("%04d-%02d-%02d", y_num, m, d_num)
			local year_str = string.format("%04d", y_num)
			local month_str = string.format("%02d", m)
			return date_str, year_str, month_str
		end
	end

	-- Fallback to today if no header date is found
	local now = os.time()
	return os.date("%Y-%m-%d", now), os.date("%Y", now), os.date("%m", now)
end

--- Parses raw FitNotes export text into structured exercise and volume data.
--- Identifies bodyweight exercises and computes the total lifted volume.
--- @param raw_text string Raw text payload containing the FitNotes export.
--- @return string date_str Extracted or fallback workout date (`YYYY-MM-DD`).
--- @return string year_str Extracted or fallback year (`YYYY`).
--- @return string month_str Extracted or fallback month (`MM`).
--- @return table valid_exercises List of parsed exercise tables with sets and metrics.
--- @return number total_volume Calculated cumulative weight-reps volume.
local function parse_fitnotes_text(raw_text)
	local lines = {}
	for line in raw_text:gmatch("[^\r\n]+") do
		local trimmed = line:match("^%s*(.-)%s*$")
		if trimmed ~= "" then
			table.insert(lines, trimmed)
		end
	end

	local now = os.time()
	local date_str = os.date("%Y-%m-%d", now)
	local year_str = os.date("%Y", now)
	local month_str = os.date("%m", now)

	if #lines > 0 and lines[1]:match("FitNotes Workout") then
		date_str, year_str, month_str = parse_date_from_header(lines[1])
	end

	local exercises = {}
	local current_ex = nil

	for _, line in ipairs(lines) do
		if not line:match("^FitNotes Workout") then
			local weight_str, _, reps_str = line:match("^-%s*([%d%.]+)%s*([a-zA-Z]*)%s*x%s*(%d+)%s*reps")
			if weight_str and current_ex then
				local weight = tonumber(weight_str)
				local reps = tonumber(reps_str)

				if current_ex.is_bodyweight and weight <= 1.0 then
					weight = 0.0
				end

				table.insert(current_ex.sets, { weight = weight, reps = reps })
			else
				local cleaned_title = line:gsub("[%*%-%_]", ""):match("^%s*(.-)%s*$")
				if cleaned_title and cleaned_title ~= "" then
					local is_bw = false
					local lower_title = cleaned_title:lower()
					for _, kw in ipairs(BODYWEIGHT_KEYWORDS) do
						if lower_title:find(kw, 1, true) then
							is_bw = true
							break
						end
					end
					current_ex = {
						name = cleaned_title,
						is_bodyweight = is_bw,
						sets = {},
					}
					table.insert(exercises, current_ex)
				end
			end
		end
	end

	local valid_exercises = {}
	local total_volume = 0.0
	for _, ex in ipairs(exercises) do
		if #ex.sets > 0 then
			table.insert(valid_exercises, ex)
			for _, s in ipairs(ex.sets) do
				total_volume = total_volume + (s.weight * s.reps)
			end
		end
	end

	total_volume = math.floor(total_volume * 100 + 0.5) / 100
	return date_str, year_str, month_str, valid_exercises, total_volume
end

--- Parses frontmatter metadata and body content from an existing markdown file.
--- @param content? string Raw file content string.
--- @return table metadata Parsed metadata table containing raw lines, fields, date, and bodyweight.
--- @return string body Markdown body content excluding the frontmatter block.
local function parse_frontmatter(content)
	if not content then
		return { raw_lines = {}, fields = {}, bodyweight_kg = 64.0 }, ""
	end

	-- Strip any leading whitespace or invisible BOM characters at the very start
	content = content:gsub("^[%s\239\187\191]+", "")

	if not content:match("^---") then
		print("DEBUG: File does not start with --- frontmatter")
		return { raw_lines = {}, fields = {}, bodyweight_kg = 64.0 }, content
	end

	local line_list = {}
	for line in content:gmatch("[^\r\n]+") do
		table.insert(line_list, line)
	end

	local raw_lines = {}
	local fields = {}
	local end_idx = 1
	local fm_ended = false

	-- Loop through lines starting after the first '---'
	for i = 2, #line_list do
		if line_list[i]:match("^---") then
			end_idx = i
			fm_ended = true
			break
		else
			table.insert(raw_lines, line_list[i])
			local key, val = line_list[i]:match("^([%w_-]+):%s*(.*)$")
			if key then
				fields[key] = val
			end
		end
	end

	-- Reconstruct the body content after the closing '---'
	local body_lines = {}
	if fm_ended then
		for i = end_idx + 1, #line_list do
			table.insert(body_lines, line_list[i])
		end
	else
		body_lines = line_list -- Fallback if closing --- wasn't found
	end
	local body = table.concat(body_lines, "\n")

	local metadata = {
		raw_lines = raw_lines,
		fields = fields,
		date = fields["id"] or fields["date"],
		bodyweight_kg = tonumber(fields["bodyweight_kg"]) or 64.0,
	}

	return metadata, body
end

--- Loads an existing journal post or initializes a new one using the default daily template.
--- @param file_path string Target filesystem path for the journal entry.
--- @param output_dir string Root directory path for journal storage.
--- @return table metadata Parsed metadata table.
--- @return string content Processed file/template content string.
--- @return table workout_data Initialized workout status table.
local function load_or_create_post(file_path, output_dir)
	local content = ""
	local metadata = {
		bodyweight_kg = 64.0,
		raw_lines = {},
		fields = {},
	}
	local workout_data = { completed = true, volume_kg = 0 }

	if vim.fn.filereadable(file_path) == 1 then
		local f = io.open(file_path, "r")
		if f then
			content = f:read("*a")
			f:close()
		end

		metadata, content = parse_frontmatter(content)
	else
		local vault_root = vim.fn.expand(output_dir)
		while vault_root ~= "/" and vim.fn.fnamemodify(vault_root, ":t") ~= "LifeOS" do
			vault_root = vim.fn.fnamemodify(vault_root, ":h")
		end
		local template_path = vault_root .. "/00-09_Support/02_Templates/Daily_Template.md"
		if vim.fn.filereadable(template_path) == 1 then
			local tf = io.open(template_path, "r")
			if tf then
				content = tf:read("*a")
				tf:close()
			end
			metadata, content = parse_frontmatter(content)
		end
	end
	return metadata, content, workout_data
end

--- Updates or appends the workout markdown section with parsed exercise logs and routine heading.
--- @string content Existing body content of the markdown note.
--- @param exercises table List of parsed exercises with weights and set rep structures.
--- @string heading Selected category routine heading/title.
--- @return string content Updated body content string.
local function update_workout_markdown_section(content, exercises, heading)
	local workout_lines = { "## Workout\n" }

	if heading and heading ~= "" then
		table.insert(workout_lines, "- " .. heading .. "\n")
	end

	for _, ex in ipairs(exercises) do
		local sets_parts = {}
		for _, s in ipairs(ex.sets) do
			table.insert(sets_parts, string.format("%gx%d", s.weight, s.reps))
		end
		local sets_str = table.concat(sets_parts, "\\")
		table.insert(workout_lines, string.format("  - [x] %s (Reps: %s)", ex.name, sets_str))
	end

	local new_workout_block = table.concat(workout_lines, "\n")

	if content:find("## Workout", 1, true) then
		local parts = vim.split(content, "## Workout", { plain = true })
		local before_section = vim.trim(parts[1])
		local after_section = ""
		if #parts > 1 and parts[2]:find("\n#", 1, true) then
			local sub_parts = vim.split(parts[2], "\n#", { plain = true })
			if #sub_parts > 1 then
				after_section = "\n#" .. table.concat(sub_parts, "\n#", 2)
			end
		end
		return before_section .. "\n\n" .. new_workout_block .. "\n\n" .. vim.trim(after_section) .. "\n"
	else
		return vim.trim(content) .. "\n\n" .. new_workout_block .. "\n"
	end
end

--- Serializes and saves the updated post metadata frontmatter and body content back to disk.
--- @param file_path string Target file destination path.
--- @param metadata table Frontmatter metadata table.
--- @param workout_data table Workout completion and volume statistics table.
--- @string content Markdown body content string.
local function save_post(file_path, metadata, workout_data, content)
	local fm_lines = { "---" }
	local updated_keys = {}
	local skip_workout_block = false

	if metadata.raw_lines then
		for _, line in ipairs(metadata.raw_lines) do
			local key = line:match("^([%w_-]+):")

			-- Skip old nested workout lines if we encounter them, so we can rewrite them cleanly
			if key == "workout" then
				skip_workout_block = true
			elseif skip_workout_block and (line:match("^%s+") or line == "") then
				-- Still inside the indented workout block, skip it
			else
				skip_workout_block = false
				if key == "bodyweight_kg" and metadata.bodyweight_kg then
					table.insert(fm_lines, string.format("bodyweight_kg: %.1f", metadata.bodyweight_kg))
					updated_keys["bodyweight_kg"] = true
				else
					table.insert(fm_lines, line)
				end
			end
		end
	end

	-- If bodyweight_kg wasn't in original frontmatter, add it
	if metadata.bodyweight_kg and not updated_keys["bodyweight_kg"] then
		table.insert(fm_lines, string.format("bodyweight_kg: %.1f", metadata.bodyweight_kg))
	end

	-- Add/Update workout block
	table.insert(fm_lines, "workout:")
	table.insert(fm_lines, string.format("  completed: %s", tostring(workout_data.completed)))
	table.insert(fm_lines, string.format("  volume_kg: %.2f", workout_data.volume_kg))
	table.insert(fm_lines, "---")

	local final_content = table.concat(fm_lines, "\n") .. "\n\n" .. content
	local f = io.open(file_path, "w")
	if f then
		f:write(final_content)
		f:close()
	end
end

--- Converts raw FitNotes text into a structured journal markdown entry and updates stats.
--- @string raw_text Raw content block from the FitNotes export.
--- @string? output_dir Optional custom directory path for output files.
--- @string? heading Optional routine category header string.
--- @return string file_path Absolute path of the generated or modified journal entry file.
function M.convert_to_journal(raw_text, output_dir, heading)
	output_dir = output_dir or "~/LifeOS/10-19_Inbox_&_Journals/12_Journal"

	local date_str, year_str, month_str, exercises, total_volume = parse_fitnotes_text(raw_text)

	local target_dir = vim.fn.expand(output_dir) .. "/" .. year_str .. "/" .. month_str
	vim.fn.mkdir(target_dir, "p")

	local file_path = target_dir .. "/" .. date_str .. ".md"

	local metadata, content, workout_data = load_or_create_post(file_path, output_dir)
	workout_data.completed = true
	workout_data.volume_kg = total_volume

	content = update_workout_markdown_section(content, exercises, heading)

	save_post(file_path, metadata, workout_data, content)

	return file_path
end

--- Reads clipboard data, prompts the user to select an appropriate routine category via `vim.ui.select`,
--- processes the workout entry, and opens the resulting daily journal file in Neovim.
--- @return nil
function M.import_clipboard()
	local clip = vim.fn.getreg("+")
	if not clip or clip == "" then
		vim.notify("Error: System clipboard is empty!", vim.log.levels.ERROR, { title = "LifeOS" })
		return
	end

	local options = {
		"Upper (A) - (Strength Focus) 💪",
		"Lower (A) - (Quad Focus) 🦵",
		"Upper (B) - (Hypertrophy Focus) 🏋️‍♀️",
		"Lower (B) - (Posterior Focus) 🦵",
		"Specialization",
	}

	vim.ui.select(options, {
		prompt = "Select Workout Routine:",
	}, function(choice)
		if not choice then
			return
		end

		local journal_dir = vim.fn.expand(M.root_dir .. config.paths.journal_folder)
		local target_file = M.convert_to_journal(clip, journal_dir, choice)

		if target_file ~= "" and vim.fn.filereadable(target_file) == 1 then
			vim.cmd("edit " .. vim.fn.fnameescape(target_file))
			vim.notify(
				"Imported workout for " .. vim.fn.fnamemodify(target_file, ":t:r"),
				vim.log.levels.INFO,
				{ title = "LifeOS FitNotes" }
			)
		else
			vim.notify("Workout imported, but failed to open file.", vim.log.levels.WARN, { title = "LifeOS FitNotes" })
		end
	end)
end

--- Initializes the FitNotes module with runtime configurations and registers the user command.
--- @param opts? table Configuration options table (supports `root_dir`).
--- @return nil
function M.setup(opts)
	opts = opts or {}
	M.root_dir = opts.root_dir or vim.fn.getcwd()

	-- Register a user command
	vim.api.nvim_create_user_command("LifeFitNotesImport", function()
		M.import_clipboard()
	end, {})
end

return M
