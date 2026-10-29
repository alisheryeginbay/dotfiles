return {
  { 'miikanissi/modus-themes.nvim', priority = 1000 },
  { 'nvim-tree/nvim-web-devicons', lazy = true },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    opts = {
      options = {
        theme = 'auto',
        icons_enabled = true,
      },
    },
  },
}
