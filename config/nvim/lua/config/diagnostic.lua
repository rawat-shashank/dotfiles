-- diagnostics enable virtual text
vim.diagnostic.config({
	virtual_text = true,
})

-- move all diagnostic into quick fix list
vim.keymap.set("n", "<leader>sd", function()
	vim.diagnostic.setqflist()
	vim.cmd("copen")
end, { silent = true, desc = "[s]how [d]iagnostics" })
