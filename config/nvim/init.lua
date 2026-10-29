vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require 'config.lazy'
require 'config.lsp'

-- Picks Operandi or Vivendi from 'background', which Neovim detects from
-- the terminal (and updates when Ghostty switches).
vim.cmd [[colorscheme modus]]
