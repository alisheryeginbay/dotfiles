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
      -- Sidebar file tree; oil handles directory buffers instead.
      explorer = { enabled = true, replace_netrw = false },
      picker = {
        sources = {
          -- show dotfiles and gitignored files
          explorer = { hidden = true, ignored = true },
        },
      },
    },
  },
}
