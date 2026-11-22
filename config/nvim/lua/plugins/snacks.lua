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
      {
        '<leader>.',
        function()
          Snacks.scratch()
        end,
        desc = 'Toggle scratch buffer',
      },
      {
        '<leader>S',
        function()
          Snacks.scratch.select()
        end,
        desc = 'Select scratch buffer',
      },
      {
        '<leader>z',
        function()
          Snacks.zen()
        end,
        desc = 'Toggle zen mode',
      },
      {
        '<leader>Z',
        function()
          Snacks.zen.zoom()
        end,
        desc = 'Toggle zoom',
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
      -- Persistent per-cwd scratch buffers in a float.
      scratch = { enabled = true },
      -- Centered distraction-free window; zoom just maximizes.
      zen = {
        enabled = true,
        -- Opaque backdrop in the Normal bg instead of a see-through black tint.
        win = { backdrop = { transparent = false, blend = 99 } },
      },
      picker = {
        sources = {
          -- show dotfiles and gitignored files
          explorer = { hidden = true, ignored = true },
        },
      },
    },
  },
}
