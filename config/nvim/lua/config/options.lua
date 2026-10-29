vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.scrolloff = 8
vim.opt.mouse = ''
vim.opt.signcolumn = 'yes'
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.inccommand = 'split'

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.timeoutlen = 300

-- Move by wrapped screen lines; a count (e.g. 5j) still jumps real lines,
-- so relative line numbers keep working.
for _, key in ipairs { 'j', 'k', '<Down>', '<Up>' } do
  local g = 'g' .. key
  vim.keymap.set({ 'n', 'x' }, key, function()
    return vim.v.count == 0 and g or key
  end, { expr = true, silent = true })
end
vim.opt.breakindent = true

vim.opt.clipboard = 'unnamedplus'

vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight-yank', {}),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.diagnostic.config {
  -- Full message under the cursor's line only.
  virtual_lines = { current_line = true },
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
