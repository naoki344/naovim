-- Plugin management with lazy.nvim (using fzf instead of telescope)
require('lazy-setup')

-- Configure plugins after Neovim starts
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Git signs (clear and distinct from error indicators)
    vim.g.gitgutter_sign_added = '+'
    vim.g.gitgutter_sign_modified = '~'
    vim.g.gitgutter_sign_removed = '-'
    vim.g.gitgutter_sign_removed_first_line = '‾'
    vim.g.gitgutter_sign_modified_removed = '~-'
    vim.g.gitgutter_max_signs = 500

    -- Lightline
    vim.g.lightline = {
      colorscheme = 'landscape',
      active = {
        left = {
          {'mode', 'paste'},
          {'readonly', 'filename', 'modified'},
        },
        right = {
          {'lineinfo'},
          {'percent'},
          {'fileformat', 'fileencoding', 'filetype'},
        }
      },
    }

    -- Go settings
    vim.g.go_metalinter_command = 'golangci-lint'

    -- Define diagnostic signs for nvim-tree before setup
    vim.fn.sign_define("NvimTreeDiagnosticErrorIcon", { text = "✗", texthl = "DiagnosticError" })
    vim.fn.sign_define("NvimTreeDiagnosticWarnIcon", { text = "", texthl = "DiagnosticWarn" })
    vim.fn.sign_define("NvimTreeDiagnosticInfoIcon", { text = "", texthl = "DiagnosticInfo" })
    vim.fn.sign_define("NvimTreeDiagnosticHintIcon", { text = "", texthl = "DiagnosticHint" })

    -- Setup nvim-tree
    local ok_tree, nvim_tree = pcall(require, 'nvim-tree')
    if ok_tree then
      -- Custom key mappings for nvim-tree
      local function nvim_tree_on_attach(bufnr)
        local api = require('nvim-tree.api')

        local function opts(desc)
          return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end

        -- Default mappings
        api.config.mappings.default_on_attach(bufnr)

        -- Custom mappings for better split handling
        -- <CR> or o: Open in last focused window (allows multiple files in different splits)
        vim.keymap.set('n', '<CR>', api.node.open.edit, opts('Open'))
        vim.keymap.set('n', 'o', api.node.open.edit, opts('Open'))

        -- v: Open in new vertical split
        vim.keymap.set('n', 'v', api.node.open.vertical, opts('Open: Vertical Split'))
        vim.keymap.set('n', '<C-v>', api.node.open.vertical, opts('Open: Vertical Split'))

        -- s: Open in new horizontal split
        vim.keymap.set('n', 's', api.node.open.horizontal, opts('Open: Horizontal Split'))
        vim.keymap.set('n', '<C-x>', api.node.open.horizontal, opts('Open: Horizontal Split'))

        -- t: Open in new tab
        vim.keymap.set('n', 't', api.node.open.tab, opts('Open: New Tab'))
        vim.keymap.set('n', '<C-t>', api.node.open.tab, opts('Open: New Tab'))
      end

      nvim_tree.setup({
        disable_netrw = false,
        hijack_netrw = false,
        sync_root_with_cwd = true,
        respect_buf_cwd = true,
        on_attach = nvim_tree_on_attach,
        update_focused_file = {
          enable = true,
          update_root = true,
          ignore_list = {},
        },
        view = {
          width = 30,
          side = "left",
          preserve_window_proportions = false,
        },
        diagnostics = {
          enable = false,
        },
        renderer = {
          icons = {
            webdev_colors = true,
            git_placement = "before",
            show = {
              git = true,
              folder = true,
              file = true,
              folder_arrow = true,
            },
            glyphs = {
              git = {
                unstaged = "~",
                staged = "+",
                unmerged = "U",
                renamed = "R",
                untracked = "?",
                deleted = "-",
                ignored = "◌",
              },
            },
          },
          highlight_git = true,
          root_folder_modifier = ":~",
        },
        filters = {
          dotfiles = false,
          custom = { "__pycache__", ".mypy_cache", "*.pyc" },
        },
        actions = {
          open_file = {
            quit_on_open = false,
            resize_window = true,
            window_picker = {
              enable = false,
            },
          },
        },
      })


      -- Function to check if nvim-tree is open
      local function is_nvim_tree_open()
        local tree_wins = vim.tbl_filter(function(win_id)
          local buf_id = vim.api.nvim_win_get_buf(win_id)
          return vim.api.nvim_buf_get_option(buf_id, 'filetype') == 'NvimTree'
        end, vim.api.nvim_list_wins())
        return #tree_wins > 0
      end

      -- Function to open nvim-tree and focus back to main window
      local function open_tree_and_focus_back()
        vim.cmd('NvimTreeOpen')
        -- If we have multiple windows, focus on the non-tree window
        if #vim.api.nvim_list_wins() > 1 then
          vim.cmd('wincmd p')
        end
      end

      -- Create custom highlight for error files
      vim.api.nvim_set_hl(0, "NvimTreeErrorFile", { fg = "#ff6c6b", bold = true })

      -- Custom function to highlight error files in nvim-tree
      local function highlight_error_files()
        local nvim_tree_api_ok, nvim_tree_api = pcall(require, 'nvim-tree.api')
        if not nvim_tree_api_ok then return end

        -- Get all diagnostics
        local diagnostics = vim.diagnostic.get()
        local files_with_errors = {}
        local dirs_with_errors = {}

        for _, diag in ipairs(diagnostics) do
          if diag.severity == vim.diagnostic.severity.ERROR then
            local file = vim.api.nvim_buf_get_name(diag.bufnr)
            if file and file ~= "" then
              files_with_errors[file] = true

              -- Also mark all parent directories as having errors
              local dir = vim.fn.fnamemodify(file, ":h")
              while dir and dir ~= "/" and dir ~= "" do
                dirs_with_errors[dir] = true
                local parent = vim.fn.fnamemodify(dir, ":h")
                if parent == dir then break end
                dir = parent
              end
            end
          end
        end

        -- Find nvim-tree buffer and add virtual text
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) then
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if buf_name:match("NvimTree") then
              -- Clear existing virtual text
              local ns_id = vim.api.nvim_create_namespace("nvim_tree_errors")
              vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

              -- Add virtual text for each line
              local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
              for i, line in ipairs(lines) do
                local marked = false

                -- Check for error files
                for file_path, _ in pairs(files_with_errors) do
                  local filename = vim.fn.fnamemodify(file_path, ":t")
                  if line:find(filename, 1, true) and not marked then
                    vim.api.nvim_buf_set_extmark(buf, ns_id, i - 1, 0, {
                      virt_text = {{ " ✗", "DiagnosticError" }},
                      virt_text_pos = "eol",
                    })
                    marked = true
                    break
                  end
                end

                -- Check for error directories (only if not already marked as file)
                if not marked then
                  for dir_path, _ in pairs(dirs_with_errors) do
                    local dirname = vim.fn.fnamemodify(dir_path, ":t")
                    if dirname ~= "" and line:find(dirname, 1, true) then
                      vim.api.nvim_buf_set_extmark(buf, ns_id, i - 1, 0, {
                        virt_text = {{ " ✗", "DiagnosticError" }},
                        virt_text_pos = "eol",
                      })
                      marked = true
                      break
                    end
                  end
                end
              end
              break
            end
          end
        end
      end

      -- Update when diagnostics change
      vim.api.nvim_create_autocmd("DiagnosticChanged", {
        callback = function()
          vim.defer_fn(highlight_error_files, 100)
        end,
      })

      -- Update when nvim-tree buffer changes
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "NvimTree_*",
        callback = function()
          vim.defer_fn(highlight_error_files, 100)
        end,
      })

      -- Update when nvim-tree is refreshed or redrawn
      vim.api.nvim_create_autocmd("User", {
        pattern = {"NvimTreeSetup", "NvimTreeRefresh"},
        callback = function()
          vim.defer_fn(highlight_error_files, 100)
        end,
      })

      -- Update on buffer write (when errors might change)
      vim.api.nvim_create_autocmd("BufWritePost", {
        callback = function()
          vim.defer_fn(highlight_error_files, 200)
        end,
      })

      -- Continuously monitor nvim-tree buffer changes
      vim.api.nvim_create_autocmd("TextChanged", {
        pattern = "NvimTree_*",
        callback = function()
          vim.defer_fn(highlight_error_files, 50)
        end,
      })

      -- Monitor cursor movement in nvim-tree
      vim.api.nvim_create_autocmd("CursorMoved", {
        pattern = "NvimTree_*",
        callback = function()
          vim.defer_fn(highlight_error_files, 50)
        end,
      })

      -- Auto-open functionality disabled to prevent unwanted behavior during window navigation
      -- Use <C-n> or :NvimTreeToggle to manually open/close nvim-tree
    end

    -- Setup autopairs
    local ok_autopairs, autopairs = pcall(require, 'nvim-autopairs')
    if ok_autopairs then
      autopairs.setup()
    end

    -- Telescope setup removed

    -- Setup CtrlP manually if not loaded by lazy
    local ctrlp_ok = vim.fn.exists(':CtrlP') == 2
    if ctrlp_ok then
      -- CtrlP additional settings
      vim.g.ctrlp_map = '<c-p>'
      vim.g.ctrlp_working_path_mode = 'ra'
      print('CtrlP setup completed')
    else
      print('CtrlP not available yet')
    end

    -- LSP and completion setup is handled in lsp.lua

    -- Force colorizer to work on all buffers
    vim.schedule(function()
      local ok_colorizer = pcall(require, 'colorizer')
      if ok_colorizer then
        vim.cmd('ColorizerReloadAllBuffers')
        print('Colorizer reloaded for all buffers')
      end
    end)

    -- Setup Tailwind CSS colors
    local ok_tw_colors, tw_colors = pcall(require, 'tailwindcss-colors')
    if ok_tw_colors then
      print('Tailwind CSS colors plugin loaded')
    end

    -- Auto-open Telescope oldfiles on startup (if no file arguments)
    vim.schedule(function()
      -- Only open if no files were specified on command line
      local args = vim.fn.argv()
      if #args == 0 then
        -- Delay to ensure Telescope is fully loaded
        vim.defer_fn(function()
          local ok_telescope = pcall(require, 'telescope.builtin')
          if ok_telescope then
            vim.cmd('Telescope oldfiles cwd_only=true')
          end
        end, 100)
      end
    end)
  end
})

-- nvim-tree auto-open temporarily disabled to avoid fzf conflicts
-- Use :NvimTreeToggle manually when needed
-- vim.api.nvim_create_autocmd("VimEnter", {
--   nested = true,
--   callback = function()
--     vim.defer_fn(function()
--       vim.cmd('NvimTreeOpen')
--       if #vim.api.nvim_list_wins() > 1 then
--         vim.cmd('wincmd p')
--       end
--     end, 300)
--   end,
-- })
