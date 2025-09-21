-- Plugin management with dein.vim
require('dein_setup')

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
      nvim_tree.setup({
        disable_netrw = true,
        hijack_netrw = true,
        sync_root_with_cwd = true,
        respect_buf_cwd = true,
        update_focused_file = {
          enable = true,
          update_root = true,
          ignore_list = {},
        },
        view = {
          width = 30,
          side = "left",
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

      -- Auto-open will be handled by the global VimEnter autocmd below

      -- Auto-open nvim-tree when opening a file with a path (if not already open)
      vim.api.nvim_create_autocmd({"BufEnter"}, {
        callback = function(args)
          -- Safety check for valid buffer
          if not args.buf or not vim.api.nvim_buf_is_valid(args.buf) then
            return
          end

          -- Check if buffer is loaded
          if not vim.api.nvim_buf_is_loaded(args.buf) then
            return
          end

          -- Get buffer info safely
          local ok, file = pcall(vim.api.nvim_buf_get_name, args.buf)
          if not ok or not file then
            return
          end

          -- Only trigger for real files (not empty buffers or special buffers)
          if file ~= "" and vim.fn.isdirectory(file) == 0 then
            local buftype_ok, buftype = pcall(function() return vim.bo[args.buf].buftype end)
            local filetype_ok, filetype = pcall(function() return vim.bo[args.buf].filetype end)

            -- Skip special buffers like Telescope, NvimTree, etc.
            local skip_filetypes = {
              'TelescopePrompt',
              'TelescopeResults',
              'NvimTree',
              'help',
              'qf',
              'quickfix',
              'terminal'
            }

            -- Check if Telescope is currently active
            local telescope_active = false
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              local win_buf = vim.api.nvim_win_get_buf(win)
              local win_ft_ok, win_ft = pcall(vim.api.nvim_buf_get_option, win_buf, 'filetype')
              if win_ft_ok and (win_ft == 'TelescopePrompt' or win_ft == 'TelescopeResults') then
                telescope_active = true
                break
              end
            end

            if buftype_ok and buftype == "" and
               filetype_ok and not vim.tbl_contains(skip_filetypes, filetype) and
               not telescope_active then
              if not is_nvim_tree_open() then
                -- Defer the tree opening to avoid conflicts with other plugins
                vim.defer_fn(function()
                  if not is_nvim_tree_open() then
                    open_tree_and_focus_back()
                  end
                end, 100)
              end
            end
          end
        end,
      })
    end

    -- Setup autopairs
    local ok_autopairs, autopairs = pcall(require, 'nvim-autopairs')
    if ok_autopairs then
      autopairs.setup()
    end

    -- Telescope setup removed

    -- LSP and completion setup is handled in lsp.lua
  end
})

-- Setup nvim-tree auto-open outside the VimEnter callback
vim.api.nvim_create_autocmd("VimEnter", {
  nested = true,
  callback = function()
    -- Ensure we're after all other VimEnter events
    vim.schedule(function()
      local ok_tree = pcall(require, 'nvim-tree.api')
      if ok_tree then
        -- Check if nvim-tree is not already open
        local tree_wins = vim.tbl_filter(function(win_id)
          local buf_id = vim.api.nvim_win_get_buf(win_id)
          local ok, filetype = pcall(vim.api.nvim_buf_get_option, buf_id, 'filetype')
          return ok and filetype == 'NvimTree'
        end, vim.api.nvim_list_wins())

        if #tree_wins == 0 then
          vim.cmd('NvimTreeOpen')
          -- If we have multiple windows, focus on the non-tree window
          if #vim.api.nvim_list_wins() > 1 then
            vim.cmd('wincmd p')
          end
        end
      end
    end)
  end,
})