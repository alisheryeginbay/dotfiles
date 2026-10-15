return {
  {
    'R-nvim/R.nvim',
    -- R.nvim lazy-loads itself per filetype.
    lazy = false,
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('r').setup {}
    end,
  },
}
