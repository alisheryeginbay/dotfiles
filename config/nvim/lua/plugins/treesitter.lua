return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install {
        'r',
        'rnoweb',
        'markdown',
        'markdown_inline',
        'yaml',
        'python',
        'rust',
        'toml',
        'nix',
        'lua',
        'fish',
        'bash',
        'json',
      }
      -- Start treesitter for any filetype that has a parser installed.
      vim.api.nvim_create_autocmd('FileType', {
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },
}
