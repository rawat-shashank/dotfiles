-- ============================================================================
-- LifeOS Module: Nutrients & Macro Tracking
-- ============================================================================
-- DOCUMENTATION & SPECIFICATION:
--
-- 1. Overview & Functionality:
--    - Manages food intake and macro tracking inside Neovim buffers.
--    - Loads a nutrient database from JSON (`db.json`).
--    - Provides an `fzf-lua` picker to search food items and compute macros based on user-entered weight.
--    - Automatically appends formatted checklist items into the current buffer's `## Food Intake` section.
--
-- 2. Dependencies:
--    - fzf-lua
--
-- 3. Usage Examples & Commands:
--    - Initialize the plugin in your Neovim configuration:
--      `require("lifeos.macros").setup()`
--    - Manually trigger the macro capture prompt in Normal mode:
--      `:lua require("lifeos.macros").search()`
--    - Default Keymap:
--      `<leader>cm` ([c]apture [m]acros)
--
-- 4. Example JSON Database Format (`db.json`):
--    ```json
--    {
--      "chicken_breast": { "kcal": 165, "p": 31.0, "c": 0.0, "f": 3.6 },
--      "white_rice": { "kcal": 130, "p": 2.7, "c": 28.0, "f": 0.3 }
--    }
--    ```
-- ============================================================================

local M = {}

local db_path = vim.fn.stdpath("config") .. "/lua/lifeos/macros/db.json"

--- Loads and decodes the nutrient database JSON file from disk.
--- @return table? db Decoded table containing food nutrient definitions, or nil on failure.
local function load_db()
	local file = io.open(db_path, "r")
	if not file then
		vim.notify("Nutrients DB not found at " .. db_path, vim.log.levels.ERROR)
		return nil
	end
	local content = file:read("*a")
	file:close()
	return vim.json.decode(content)
end

--- Calculates total calories and macronutrients (protein, carbs, fats) for a given food item weight.
--- @param item string Internal key name of the food item.
--- @param data table Nutrient data table per 100g (kcal, p, c, f).
--- @param weight number Weight of the food item in grams.
--- @return string formatted_line Formatted markdown checklist item string.
local function calculate_macros(item, data, weight)
	local factor = weight / 100
	local kcal = math.floor((data.kcal * factor) + 0.5)
	local p = string.format("%.1f", data.p * factor)
	local c = string.format("%.1f", data.c * factor)
	local f = string.format("%.1f", data.f * factor)

	local display_name = item:gsub("_", " ")
	return string.format("- [x] 1 %s - %gg - (%d kcal | %sP\\%sC\\%sF)", display_name, weight, kcal, p, c, f)
end

--- Updates the `## Food Intake` section in the target buffer by inserting the new food entry line.
--- @param bufnr? integer Buffer handle number (defaults to 0 for current buffer).
--- @string new_item_line Formatted checklist string line to insert.
--- @return nil
local function update_food_intake_section(bufnr, new_item_line)
	bufnr = bufnr or 0
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local header_idx = nil
	for i, line in ipairs(lines) do
		if vim.startswith(line, "## Food Intake") then
			header_idx = i
			break
		end
	end

	if not header_idx then
		vim.notify("Could not find '## Food Intake' section in buffer.", vim.log.levels.ERROR)
		return
	end

	local section_end_idx = #lines
	for i = header_idx + 1, #lines do
		if vim.startswith(lines[i], "## ") then
			section_end_idx = i - 1
			break
		end
	end

	-- Preserve all existing lines within the section
	local section_lines = {}
	for i = header_idx + 1, section_end_idx do
		table.insert(section_lines, lines[i])
	end

	-- Find the last checklist item in the section to append after it
	local last_item_idx = nil
	for i = #section_lines, 1, -1 do
		if section_lines[i]:match("^%s*%- %[.%]") then
			last_item_idx = i
			break
		end
	end

	if last_item_idx then
		-- Insert the new item directly after the last checklist item without adding extra blank lines
		table.insert(section_lines, last_item_idx + 1, new_item_line)
	else
		-- If no items exist yet, add it to the top of the section
		table.insert(section_lines, 1, new_item_line)
	end

	-- Reconstruct the buffer lines
	local new_lines = {}
	for i = 1, header_idx do
		table.insert(new_lines, lines[i])
	end

	for _, line in ipairs(section_lines) do
		table.insert(new_lines, line)
	end

	for i = section_end_idx + 1, #lines do
		table.insert(new_lines, lines[i])
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
end

--- Opens an `fzf-lua` picker to search food items, prompts for weight, and updates the food intake section.
--- @return nil
function M.search()
	local fzf = require("fzf-lua")

	local db = load_db()
	if not db then
		return
	end

	local entries = {}
	local lookup = {}

	local keys = {}
	for key in pairs(db) do
		table.insert(keys, key)
	end
	table.sort(keys)

	for _, key in ipairs(keys) do
		local data = db[key]
		local display_name = key:gsub("_", " ")
		local details = string.format("(100g: %dkcal | %gP\\%gC\\%gF)", data.kcal, data.p, data.c, data.f)
		local display_str = string.format("%-25s %s", display_name, details)

		table.insert(entries, display_str)
		lookup[display_str] = {
			value = key,
			data = data,
		}
	end

	fzf.fzf_exec(entries, {
		prompt = "Nutrient Search> ",
		actions = {
			["default"] = function(selected)
				if not selected or #selected == 0 then
					return
				end

				local selected_text = selected[1]
				local selected_entry = lookup[selected_text]

				if not selected_entry then
					return
				end

				local food_key = selected_entry.value
				local food_data = selected_entry.data

				vim.ui.input(
					{ prompt = "Enter weight in grams for " .. food_key:gsub("_", " ") .. ": " },
					function(input)
						local weight = tonumber(input)
						if not weight then
							vim.notify("Invalid weight entered.", vim.log.levels.WARN)
							return
						end

						local formatted_line = calculate_macros(food_key, food_data, weight)
						update_food_intake_section(0, formatted_line)
					end
				)
			end,
		},
	})
end

function M.setup(opts)
	opts = opts or {}

	vim.api.nvim_create_user_command("LifeMacroSearch", function()
		M.search()
	end, {})
end

return M
