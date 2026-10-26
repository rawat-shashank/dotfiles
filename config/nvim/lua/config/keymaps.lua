local map = vim.keymap.set

-- FZF-Lua mappings
map("n", "<Leader>sf", "<cmd>FzfLua files<cr>", { desc = "[s]earch [f]iles" })
map("n", "<Leader>sg", "<cmd>FzfLua live_grep<cr>", { desc = "[s]earch live [g]rep" })
map("n", "<Leader>sb", "<cmd>FzfLua buffers<cr>", { desc = "[s]earch [b]uffers" })
map("n", "<leader>sn", function()
	require("fzf-lua").files({ cwd = vim.fn.stdpath("config") })
end, { desc = "[S]earch [N]eovim config files" })

-- General QoL
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear Search Highlights" })
map("i", "jk", "<ESC>", { noremap = true, silent = true, desc = "Exit insert mode" })

-- Move lines up/down (Alt + j/k)
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- Visual Mode Indentation & Paste
map("v", "<", "<gv")
map("v", ">", ">gv")
map("v", "p", '"_dP', { noremap = true, silent = true })

-- Yazi File Manager
map({ "n", "v" }, "\\", "<cmd>Yazi<cr>", { desc = "Open yazi" })
map("n", "<leader>cw", "<cmd>Yazi cwd<cr>", { desc = "Yazi in [c]urrent [w]orking dir" })
map("n", "<c-up>", "<cmd>Yazi toggle<cr>", { desc = "Resume last yazi" })

-- Which-Key
map("n", "<leader>?", function()
	require("which-key").show({ loop = false })
end, { desc = "(?) Buffer Local Keymaps" })

-- LSP Keymaps
map("n", "<Leader>ca", vim.lsp.buf.code_action, { desc = "LSP: [c]ode [a]ction" })
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition" })
map("n", "K", vim.lsp.buf.hover, { desc = "Hover Documentation" })
