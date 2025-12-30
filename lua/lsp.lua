-- LSP Configuration with mason.nvim and nvim-cmp

-- Suppress lspconfig deprecation warnings
local original_notify = vim.notify
vim.notify = function(msg, level, opts)
  -- Filter out lspconfig deprecation warnings
  if msg and msg:match("lspconfig.*deprecated") then
    return
  end
  original_notify(msg, level, opts)
end

-- Setup LSP first
local ok_lspconfig, lspconfig = pcall(require, 'lspconfig')

-- Restore original notify
vim.notify = original_notify

if not ok_lspconfig then
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

  -- Helper function to remove duplicate locations
  local function remove_duplicates(locations)
    if not locations or #locations == 0 then return locations end
    local seen = {}
    local unique = {}
    for _, loc in ipairs(locations) do
      local uri = loc.uri or loc.filename or ""
      local key = string.format("%s:%d:%d", uri, (loc.range.start or loc.start or {}).line or 0, (loc.range.start or loc.start or {}).character or 0)
      if not seen[key] then
        seen[key] = true
        table.insert(unique, loc)
      end
    end
    return unique
  end

  -- Helper function to show Telescope picker with deduped results
  local function show_telescope_deduped(method, picker_name)
    return function()
      local params = vim.lsp.util.make_position_params()
      vim.lsp.buf_request(bufnr, method, params, function(err, result, ctx)
        if err then
          vim.notify(picker_name .. " not found", vim.log.levels.WARN)
          return
        end
        if not result or #result == 0 then
          vim.notify(picker_name .. " not found", vim.log.levels.INFO)
          return
        end

        -- Remove duplicates
        local unique_result = remove_duplicates(result)

        -- If only one result, jump directly
        if #unique_result == 1 then
          vim.cmd('normal! m\'')
          -- Save current position for Ctrl+t before jumping
          local current_buf = vim.api.nvim_get_current_buf()
          local current_line = vim.fn.line('.')
          local current_col = vim.fn.col('.')
          local prev_jump = vim.g.lsp_jump_from
          vim.g.lsp_jump_from = {
            buf = current_buf,
            line = current_line,
            col = current_col,
            prev = prev_jump
          }
          vim.lsp.util.jump_to_location(unique_result[1], vim.lsp.get_client_by_id(ctx.client_id).offset_encoding)
          return
        end

        -- Set quickfix list and open with Telescope
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        local items = vim.lsp.util.locations_to_items(unique_result, client.offset_encoding)

        -- Save current position to a global variable for tag stack management
        local current_buf = vim.api.nvim_get_current_buf()
        local current_line = vim.fn.line('.')
        local current_col = vim.fn.col('.')
        local prev_jump = vim.g.lsp_jump_from
        vim.g.lsp_jump_from = {
          buf = current_buf,
          line = current_line,
          col = current_col,
          prev = prev_jump
        }

        vim.fn.setqflist(items)

        local ok_telescope, telescope = pcall(require, 'telescope.builtin')
        if ok_telescope then
          -- Clear any pending input and open Telescope with empty default text
          vim.defer_fn(function()
            -- Clear input buffer
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-u>', true, false, true), 'n', true)
            telescope.quickfix({ default_text = "" })
          end, 1)
        else
          -- Fallback to location list if Telescope not available
          vim.cmd('botright lopen')
        end
      end)
    end
  end

  -- LSP keymaps
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', show_telescope_deduped('textDocument/definition', 'Definition'), bufopts)
  -- Note: Ctrl+] is defined as a global keymap below
  vim.keymap.set('n', 'gi', show_telescope_deduped('textDocument/implementation', 'Implementation'), bufopts)
  vim.keymap.set('n', '<C-[>', show_telescope_deduped('textDocument/implementation', 'Implementation'), bufopts)


  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', show_telescope_deduped('textDocument/references', 'References'), bufopts)
  vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)

  -- Diagnostic keymaps
  vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, bufopts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, bufopts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, bufopts)
  vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, bufopts)

  -- Enable inlay hints for Go files
  if client.name == "gopls" and client.server_capabilities.inlayHintProvider then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end

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

-- Global Ctrl+] to jump to definition (with save for Ctrl+t)
-- This is set globally to override the native tag behavior and provide consistent LSP navigation
local lsp_ctrl_bracket_handler = function()
  local clients = vim.lsp.get_active_clients({ bufnr = 0 })
  if #clients > 0 then
    -- Save current position for Ctrl+t (keep history for multiple jumps)
    local prev_jump = vim.g.lsp_jump_from
    vim.g.lsp_jump_from = {
      buf = vim.api.nvim_get_current_buf(),
      line = vim.fn.line('.'),
      col = vim.fn.col('.'),
      prev = prev_jump
    }

    -- Get word under cursor for LSP definition request
    local bufnr = vim.api.nvim_get_current_buf()
    local params = vim.lsp.util.make_position_params()

    -- Request definition from LSP
    vim.lsp.buf_request(bufnr, 'textDocument/definition', params, function(err, result, ctx)
      if err then
        vim.notify("Definition not found", vim.log.levels.WARN)
        return
      end
      if not result or #result == 0 then
        vim.notify("Definition not found", vim.log.levels.INFO)
        return
      end

      -- Remove duplicates
      local seen = {}
      local unique = {}
      for _, loc in ipairs(result) do
        local uri = loc.uri or loc.filename or ""
        local key = string.format("%s:%d:%d", uri, (loc.range.start or loc.start or {}).line or 0, (loc.range.start or loc.start or {}).character or 0)
        if not seen[key] then
          seen[key] = true
          table.insert(unique, loc)
        end
      end

      -- If only one result, jump directly
      if #unique == 1 then
        vim.cmd('normal! m\'')
        vim.lsp.util.jump_to_location(unique[1], vim.lsp.get_client_by_id(ctx.client_id).offset_encoding)
        return
      end

      -- Show with Telescope quickfix
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      local items = vim.lsp.util.locations_to_items(unique, client.offset_encoding)
      vim.fn.setqflist(items)

      vim.defer_fn(function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-u>', true, false, true), 'n', true)
        local ok_telescope, telescope = pcall(require, 'telescope.builtin')
        if ok_telescope then
          telescope.quickfix({ default_text = "" })
        else
          vim.cmd('botright lopen')
        end
      end, 1)
    end)
  else
    -- Use native tag command if no LSP client
    vim.cmd('tag <cword>')
  end
end

vim.keymap.set('n', '<C-]>', lsp_ctrl_bracket_handler, { noremap = true, silent = true })

-- Global Ctrl+t to jump back to saved LSP jump position
-- Supports multiple jump history
vim.keymap.set('n', '<C-t>', function()
  if vim.g.lsp_jump_from then
    local jump_info = vim.g.lsp_jump_from
    -- Check if the buffer is still valid
    if vim.api.nvim_buf_is_valid(jump_info.buf) then
      vim.api.nvim_set_current_buf(jump_info.buf)
      vim.api.nvim_win_set_cursor(0, { jump_info.line, jump_info.col - 1 })
    else
      -- If buffer is invalid, try to restore the previous jump
      vim.notify("Saved buffer is no longer valid", vim.log.levels.WARN)
    end
    -- Restore previous jump position (history)
    vim.g.lsp_jump_from = jump_info.prev
  else
    vim.notify("No LSP jump to go back to", vim.log.levels.WARN)
  end
end, { noremap = true, silent = true })

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
        "gopls",       -- Go
        "pyright",     -- Python
        "ts_ls",       -- TypeScript/JavaScript (correct name)
        "lua_ls",      -- Lua
        "tailwindcss", -- Tailwind CSS (correct name)
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
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  formatting = {
    fields = { 'kind', 'abbr', 'menu' },
    format = function(entry, vim_item)
      local kind_icons = {
        Text = "󰉿",
        Method = "󰆧",
        Function = "󰊕",
        Constructor = "",
        Field = "󰜢",
        Variable = "󰀫",
        Class = "󰠱",
        Interface = "",
        Module = "",
        Property = "󰜢",
        Unit = "󰑭",
        Value = "󰎠",
        Enum = "",
        Keyword = "󰌋",
        Snippet = "",
        Color = "󰏘",
        File = "󰈙",
        Reference = "󰈇",
        Folder = "󰉋",
        EnumMember = "",
        Constant = "󰏿",
        Struct = "󰙅",
        Event = "",
        Operator = "󰆕",
        TypeParameter = "",
      }
      -- アイコンとテキストを設定
      vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind] or '', vim_item.kind)
      -- ソース名を表示
      vim_item.menu = ({
        nvim_lsp = '[LSP]',
        luasnip = '[Snippet]',
        buffer = '[Buffer]',
        path = '[Path]',
      })[entry.source.name]
      return vim_item
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace,
      select = false,  -- 選択されている場合のみ確定
    }),
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
    { name = 'nvim_lsp', priority = 1000 },
    { name = 'luasnip', priority = 750 },
    { name = 'buffer', priority = 500 },
    { name = 'path', priority = 250 },
  }),
  experimental = {
    ghost_text = true,  -- プレビューテキストを表示
  },
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
    text = {
      [vim.diagnostic.severity.ERROR] = "✗",
      [vim.diagnostic.severity.WARN] = "⚠",
      [vim.diagnostic.severity.HINT] = "ⓘ",
      [vim.diagnostic.severity.INFO] = "»",
    },
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

-- Helper function to setup LSP server
local function setup_lsp_server(name, config)
  if lspconfig and lspconfig[name] then
    lspconfig[name].setup(vim.tbl_extend('force', {
      on_attach = on_attach,
      capabilities = capabilities,
    }, config))
    -- Silently configured
  end
end

-- Configure individual LSP servers
-- Go (gopls)
setup_lsp_server('gopls', {
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
        unusedwrite = true,
        useany = true,
        nilness = true,
        shadow = true,
      },
      staticcheck = true,
      gofumpt = true,
      completeUnimported = true,
      usePlaceholders = true,
      matcher = "Fuzzy",
      symbolMatcher = "FastFuzzy",
      experimentalPostfixCompletions = true,
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
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
