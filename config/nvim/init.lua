vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.o.scrolloff = 8

vim.opt.mouse = ''

require 'config.lazy'

-- Picks Operandi or Vivendi from 'background', which Neovim detects from
-- the terminal (and updates when Ghostty switches).
vim.cmd([[colorscheme modus]])
