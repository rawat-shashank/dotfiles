return {
  "windwp/nvim-autopairs",
  config = function()
    require("nvim-autopairs").setup({
      check_ts = true, -- enable treesitter
      ts_config = {
        lua = { "string" },
        javascript = { "template_string" }
      }
    })
  end
}
