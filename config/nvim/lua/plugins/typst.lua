-- Live browser preview of .typ files that follows the cursor.
return {
  {
    'chomosuke/typst-preview.nvim',
    ft = 'typst',
    keys = {
      { '<leader>tp', '<cmd>TypstPreviewToggle<cr>', ft = 'typst', desc = 'Toggle Typst preview' },
    },
    opts = {
      -- Use the Nix binaries instead of downloading them.
      dependencies_bin = { tinymist = 'tinymist', websocat = 'websocat' },
    },
  },
}
