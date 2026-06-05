vim.o.cmdheight = 0 -- Hides the classic bottom bar completely

-- 1. Initialize UI2 safely on UIEnter
vim.api.nvim_create_autocmd("UIEnter", {
	group = vim.api.nvim_create_augroup("native-noice-ui2", { clear = true }),
	once = true,
	callback = function()
		require("vim._core.ui2").enable({
			enable = true,
			msg = {
				targets = "msg",
				msg = { timeout = 3000, border = "rounded" },
			},
		})
	end,
})

-- 2. Force the UI2 command line buffer to open in a Floating Window
vim.api.nvim_create_autocmd("FileType", {
	pattern = "cmd", -- UI2 registers the active command line as filetype "cmd"
	callback = function()
		local ui2 = require("vim._core.ui2")

		vim.schedule(function()
			-- Find the active UI2 cmdline window context
			local win = ui2.wins and ui2.wins.cmd
			if win and vim.api.nvim_win_is_valid(win) then
				-- Calculate dimensions for center screen placement
				local width = math.floor(vim.o.columns * 0.6)
				local height = 1
				local row = math.floor((vim.o.lines - height) / 3) -- Place it 1/3 down
				local col = math.floor((vim.o.columns - width) / 2) -- Center horizontally

				-- Reconfigure the window properties to be a floating modal
				vim.api.nvim_win_set_config(win, {
					relative = "editor",
					row = row,
					col = col,
					width = width,
					height = height,
					border = "rounded", -- Elegant curved borders
					style = "minimal", -- Strip text flags, line numbers, etc.
					title = " Command ", -- Noice-style centered indicator
					title_pos = "center",
				})

				-- Make sure the window local background contrasts cleanly
				-- vim.wo[win].winhl = "Normal:CmdlineNormal,FloatBorder:CmdlineBorder"
			end
		end)
	end,
})

-- 3. Aesthetics (Color codes matching a sleek theme layout)
-- local function apply_colors()
-- 	vim.api.nvim_set_hl(0, "CmdlineBorder", { fg = "None", bg = "NONE" })
-- 	vim.api.nvim_set_hl(0, "CmdlineNormal", { fg = "None", bg = "None" })
-- end
-- apply_colors()
-- vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_colors })
