vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

vim.opt.termguicolors = true

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.timeoutlen = 300

vim.o.cmdheight = 1

vim.opt.conceallevel = 0

vim.diagnostic.config {
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚',
      [vim.diagnostic.severity.WARN] = '󰀪',
      [vim.diagnostic.severity.INFO] = '󰌶',
      [vim.diagnostic.severity.HINT] = '',
    },
    texthl = {
      [vim.diagnostic.severity.ERROR] = 'ErrorMsg',
      [vim.diagnostic.severity.WARN] = 'WarningMsg',
      [vim.diagnostic.severity.INFO] = 'MoreMsg',
      [vim.diagnostic.severity.HINT] = 'Question',
    },
  },
}
