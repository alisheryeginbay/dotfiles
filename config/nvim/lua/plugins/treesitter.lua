return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      local parsers = { 'r', 'rnoweb', 'markdown', 'markdown_inline', 'yaml', 'python' }
      require('nvim-treesitter').install(parsers)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'r', 'rmd', 'quarto', 'rnoweb', 'markdown', 'yaml', 'python' },
        callback = function() pcall(vim.treesitter.start) end,
      })
    end,
  },
}
