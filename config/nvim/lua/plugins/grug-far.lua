-- Project-wide find and replace with live preview (ripgrep).
return {
  {
    'MagicDuck/grug-far.nvim',
    cmd = 'GrugFar',
    keys = {
      { '<leader>fr', function() require('grug-far').open() end, desc = 'Find and replace' },
      {
        '<leader>fr',
        function() require('grug-far').with_visual_selection() end,
        mode = 'x',
        desc = 'Find and replace selection',
      },
      {
        '<leader>fR',
        function() require('grug-far').open { prefills = { paths = vim.fn.expand '%' } } end,
        desc = 'Find and replace in current file',
      },
    },
    opts = {},
  },
}
