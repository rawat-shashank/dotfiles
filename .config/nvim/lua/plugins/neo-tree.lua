return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
    -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
  },
  config = function()
    require("neo-tree").setup({
      close_if_last_window = true,
      filesystem = {
        filtered_items = {
	        visible = true,
	        show_hidden_count = true,
	        hide_dotfiles = false,
  	      hide_gitignored = true,
	        hide_by_name = {
	          '.git',
	          '.DS_Store',
	          'thumbs.db',
	        },
	        never_show = {},
        },
      }
    })
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    vim.keymap.set('n', '<C-e>', ':Neotree filesystem reveal left toggle<CR>', {})
  end
}
