return {
  { 'miikanissi/modus-themes.nvim', priority = 1000 },
  { 'nvim-tree/nvim-web-devicons', lazy = true },
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    lazy = false,
    keys = {
      { '<leader>n', '<cmd>NvimTreeToggle<cr>', desc = 'Toggle file tree' },
    },
    opts = {
      view = { side = 'left' },
      filters = { git_ignored = false },
    },
  },
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
