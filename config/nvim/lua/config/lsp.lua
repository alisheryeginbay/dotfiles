-- rust-analyzer comes from rustup (home.nix)
vim.lsp.enable 'rust_analyzer'

-- Python: ty for types/completion, ruff for lint + format (both in home.nix).
-- ty and ruff pick up the project's .venv on their own.
vim.lsp.enable { 'ty', 'ruff' }

-- Markdown notes: wikilinks, backlinks, daily notes (home.nix)
vim.lsp.enable 'markdown_oxide'

-- :Today opens today's daily note from anywhere in the vault (cwd), unlike
-- :LspToday which only exists once markdown-oxide is attached. Reads the
-- same daily_notes_folder and dailynote keys from .moxide.toml.
vim.api.nvim_create_user_command('Today', function()
  local opts = { daily_notes_folder = '', dailynote = '%Y-%m-%d' }
  local f = io.open '.moxide.toml'
  if f then
    for line in f:lines() do
      local key, value = line:match '^%s*([%w_]+)%s*=%s*"(.-)"'
      if key and opts[key] then
        opts[key] = value
      end
    end
    f:close()
  end
  local path = os.date(opts.dailynote) .. '.md'
  if opts.daily_notes_folder ~= '' then
    path = vim.fs.joinpath(opts.daily_notes_folder, path)
  end
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.cmd.edit(path)
end, { desc = "Open today's daily note" })
vim.keymap.set('n', '<leader>d', '<cmd>Today<cr>', { desc = "Today's daily note" })

-- Nix and Lua (home.nix). nixd formats with nixfmt; Lua is formatted by
-- stylua (.stylua.toml), so lua_ls's own formatter is off.
vim.lsp.config('nixd', {
  settings = { nixd = { formatting = { command = { 'nixfmt' } } } },
})
vim.lsp.config('lua_ls', {
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = { library = { vim.env.VIMRUNTIME }, checkThirdParty = false },
    },
  },
})
vim.lsp.enable { 'nixd', 'lua_ls', 'stylua' }

-- Inferred types and parameter names inline.
vim.lsp.inlay_hint.enable()

-- Leave hover to ty; ruff's hover only explains noqa codes.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-ruff-no-hover', {}),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == 'ruff' then
      client.server_capabilities.hoverProvider = false
    end
  end,
})

-- As-you-type completion: popup shows docs beside the menu, and nothing
-- is inserted until you pick an item.
vim.opt.completeopt = { 'menuone', 'noselect', 'popup', 'fuzzy' }
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-completion', {}),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or not client:supports_method('textDocument/completion', args.buf) then
      return
    end
    -- Servers only auto-trigger on a few characters (like '.'); make
    -- every printable character a trigger so the menu opens while typing.
    local chars = {}
    for i = 32, 126 do
      chars[#chars + 1] = string.char(i)
    end
    client.server_capabilities.completionProvider.triggerCharacters = chars
    vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
  end,
})

-- Format on save with any attached server that can format. Checked at
-- save time because some servers (ruff) register formatting after attach.
vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('lsp-format-on-save', {}),
  callback = function(args)
    if #vim.lsp.get_clients { bufnr = args.buf, method = 'textDocument/formatting' } > 0 then
      vim.lsp.buf.format { bufnr = args.buf, timeout_ms = 2000 }
    end
  end,
})
