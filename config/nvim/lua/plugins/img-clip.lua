-- Paste clipboard images into markdown/typst as files plus a link.
return {
  {
    'HakonHarnes/img-clip.nvim',
    event = 'VeryLazy',
    keys = {
      { '<leader>p', '<cmd>PasteImage<cr>', desc = 'Paste image from clipboard' },
    },
    opts = {},
  },
}
