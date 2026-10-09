vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.o.scrolloff = 8

vim.opt.mouse = ''

require 'config.lazy'

vim.cmd([[colorscheme modus_operandi]])
