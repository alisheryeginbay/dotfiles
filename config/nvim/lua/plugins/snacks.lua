return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    keys = {
      {
        '<leader>n',
        function()
          Snacks.explorer()
        end,
        desc = 'Toggle file explorer',
      },
    },
    opts = {
      image = {
        enabled = true,
        -- show images in a float on cursor hover, not inline in the buffer
        doc = { inline = false, float = true },
      },
      -- Sidebar file tree; also opens for `nvim <dir>` in place of netrw.
      explorer = { enabled = true },
      picker = {
        sources = {
          -- show dotfiles and gitignored files
          explorer = { hidden = true, ignored = true },
        },
      },
    },
  },
}
