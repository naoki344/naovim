-- LSP Configuration with mason.nvim and nvim-cmp

-- Setup LSP first
local ok_lspconfig, lspconfig = pcall(require, 'lspconfig')
if not ok_lspconfig then
  print("nvim-lspconfig not available")
  return
end

-- Add LSP capabilities to completion
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp_lsp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
if ok_cmp_lsp then
  capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end

-- LSP keymaps
local on_attach = function(client, bufnr)
  local bufopts = { noremap = true, silent = true, buffer = bufnr }

  -- LSP keymaps
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)

  -- Diagnostic keymaps
  vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, bufopts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, bufopts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, bufopts)
  vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, bufopts)

  -- Show diagnostics on cursor hold for TypeScript/JavaScript files
  if client.name == "ts_ls" then
    vim.api.nvim_create_autocmd("CursorHold", {
      buffer = bufnr,
      callback = function()
        local opts = {
          focusable = false,
          close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
          border = 'rounded',
          source = 'always',
          prefix = ' ',
          scope = 'cursor',
        }
        vim.diagnostic.open_float(nil, opts)
      end
    })
  end
end

-- Auto-format on save for TypeScript/JavaScript files using LSP
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
  callback = function()
    -- Use LSP's built-in formatter (very fast, no external process needed)
    vim.lsp.buf.format({ async = false })
  end,
})

-- Setup mason for LSP server management
local ok_mason, mason = pcall(require, 'mason')
if ok_mason then
  mason.setup({
    ui = {
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗"
      }
    }
  })

  -- Setup mason-lspconfig
  local ok_mason_lsp, mason_lspconfig = pcall(require, 'mason-lspconfig')
  if ok_mason_lsp then
    -- Ensure these LSP servers are installed
    mason_lspconfig.setup({
      ensure_installed = {
        "gopls",                        -- Go
        "pyright",                      -- Python
        "typescript-language-server",   -- TypeScript/JavaScript
        "lua_ls",                       -- Lua
        "tailwindcss-language-server",  -- Tailwind CSS
        -- Ruby LSP will be handled separately due to dependency issues
      },
      automatic_installation = true,
    })
  end
else
  print("Mason not available - LSP servers need to be installed manually")
end

-- Setup nvim-cmp for completion
local ok_cmp, cmp = pcall(require, 'cmp')
if not ok_cmp then
  print("nvim-cmp not available")
  return
end

local ok_luasnip, luasnip = pcall(require, 'luasnip')
if ok_luasnip then
  require("luasnip.loaders.from_vscode").lazy_load()
end

cmp.setup({
  snippet = {
    expand = function(args)
      if ok_luasnip then
        luasnip.lsp_expand(args.body)
      end
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif ok_luasnip and luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif ok_luasnip and luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
    { name = 'path' },
  })
})

-- Setup completion for command line
cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})

-- Configure diagnostics
vim.diagnostic.config({
  virtual_text = {
    enabled = true,
    source = "if_many",
    spacing = 4,
    prefix = "●",
  },
  signs = {
    active = true,
    priority = 8,
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    focusable = false,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})

-- Diagnostic signs
local signs = { Error = "✗", Warn = "⚠", Hint = "ⓘ", Info = "»" }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- Helper function to setup LSP server
local function setup_lsp_server(name, config)
  if lspconfig and lspconfig[name] then
    lspconfig[name].setup(vim.tbl_extend('force', {
      on_attach = on_attach,
      capabilities = capabilities,
    }, config))
    print("LSP server configured: " .. name)
  else
    print("LSP server not available: " .. name)
  end
end

-- Configure individual LSP servers
-- Go (gopls)
setup_lsp_server('gopls', {
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
      },
      staticcheck = true,
      gofumpt = true,
    },
  },
})

-- Python (pyright)
setup_lsp_server('pyright', {
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true,
      },
    },
  },
})

-- TypeScript (ts_ls)
setup_lsp_server('ts_ls', {
  filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = 'all',
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
      preferences = {
        importModuleSpecifier = "relative",
        includePackageJsonAutoImports = "auto",
      },
      suggest = {
        includeCompletionsForModuleExports = true,
      },
      validate = { enable = true },
    },
    javascript = {
      inlayHints = {
        includeInlayParameterNameHints = 'all',
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
      preferences = {
        importModuleSpecifier = "relative",
        includePackageJsonAutoImports = "auto",
      },
      suggest = {
        includeCompletionsForModuleExports = true,
      },
      validate = { enable = true },
    }
  }
})

-- Ruby (solargraph) - only if available
if vim.fn.executable('solargraph') == 1 then
  setup_lsp_server('solargraph', {
    settings = {
      solargraph = {
        diagnostics = true,
        completion = true,
      },
    },
  })
else
  -- Alternative: Use ruby-lsp if available
  if vim.fn.executable('ruby-lsp') == 1 then
    setup_lsp_server('ruby_lsp', {})
  end
end

-- Lua (lua_ls)
setup_lsp_server('lua_ls', {
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      diagnostics = {
        globals = {'vim'},
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
      telemetry = {
        enable = false,
      },
    },
  },
})

-- Tailwind CSS (tailwindcss)
setup_lsp_server('tailwindcss', {
  cmd = { "tailwindcss-language-server", "--stdio" },
  filetypes = {
    "html",
    "css",
    "scss",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "svelte"
  },
  settings = {
    tailwindCSS = {
      classAttributes = { "class", "className", "classList", "ngClass" },
      lint = {
        cssConflict = "warning",
        invalidApply = "error",
        invalidConfigPath = "error",
        invalidScreen = "error",
        invalidTailwindDirective = "error",
        invalidVariant = "error",
        recommendedVariantOrder = "warning"
      },
      validate = true
    }
  }
})

-- Try to use mason's setup_handlers if available, but don't fail if not
vim.schedule(function()
  local ok_mason_lsp, mason_lspconfig = pcall(require, 'mason-lspconfig')
  if ok_mason_lsp and mason_lspconfig.setup_handlers then
    mason_lspconfig.setup_handlers({
      function(server_name)
        -- Only setup if we haven't already configured it above
        if not vim.tbl_contains({'gopls', 'pyright', 'ts_ls', 'solargraph', 'ruby_lsp', 'lua_ls', 'tailwindcss'}, server_name) then
          setup_lsp_server(server_name, {})
        end
      end,
    })
  end
end)
