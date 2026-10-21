return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      image = {
        enabled = true,
        -- show images in a float on cursor hover, not inline in the buffer
        doc = { inline = false, float = true },
      },
    },
  },
}
