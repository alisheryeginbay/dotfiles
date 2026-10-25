-- Neovim half of vim-tmux-navigator (the tmux half is in config/tmux.conf).
-- tmux passes C-h/j/k/l through to nvim; this moves between splits and
-- hands off to tmux at the edge.
return {
  {
    'christoomey/vim-tmux-navigator',
    cmd = {
      'TmuxNavigateLeft',
      'TmuxNavigateDown',
      'TmuxNavigateUp',
      'TmuxNavigateRight',
      'TmuxNavigatePrevious',
    },
    keys = {
      { '<c-h>', '<cmd>TmuxNavigateLeft<cr>', desc = 'Window/pane left' },
      { '<c-j>', '<cmd>TmuxNavigateDown<cr>', desc = 'Window/pane down' },
      { '<c-k>', '<cmd>TmuxNavigateUp<cr>', desc = 'Window/pane up' },
      { '<c-l>', '<cmd>TmuxNavigateRight<cr>', desc = 'Window/pane right' },
      { '<c-\\>', '<cmd>TmuxNavigatePrevious<cr>', desc = 'Previous window/pane' },
    },
  },
}
