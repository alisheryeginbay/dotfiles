-- Edit directories as buffers. Opens for `nvim <dir>` and on `-`;
-- the snacks explorer sidebar stays on <leader>n.
return {
  {
    'stevearc/oil.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    -- Must load at startup to take over directory buffers.
    lazy = false,
    keys = {
      { '-', '<cmd>Oil<cr>', desc = 'Open parent directory' },
    },
    opts = {
      default_file_explorer = true,
      delete_to_trash = true,
      view_options = { show_hidden = true },
    },
  },
}
