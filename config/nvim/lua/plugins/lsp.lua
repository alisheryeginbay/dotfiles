return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      -- rust-analyzer comes from rustup (home.nix)
      vim.lsp.enable 'rust_analyzer'

      -- Format on save with any attached server that can format
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-format-on-save', {}),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client or not client:supports_method('textDocument/formatting', args.buf) then
            return
          end
          vim.api.nvim_create_autocmd('BufWritePre', {
            group = vim.api.nvim_create_augroup('lsp-format-' .. args.buf, {}),
            buffer = args.buf,
            callback = function()
              vim.lsp.buf.format { bufnr = args.buf, id = client.id, timeout_ms = 2000 }
            end,
          })
        end,
      })
    end,
  },
}
