-- lazy.nvim setup for Neovim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Install lazy.nvim if not exists
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  print('Installing lazy.nvim...')
  local cmd = {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  }
  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    print('Failed to install lazy.nvim: ' .. result)
    return
  end
  print('lazy.nvim installed successfully!')
end

-- Add lazy.nvim to runtime path
vim.opt.rtp:prepend(lazypath)

-- Force reload lazy.nvim
package.loaded["lazy"] = nil
local ok, lazy = pcall(require, "lazy")
if not ok then
  print('Error loading lazy.nvim: ' .. tostring(lazy))
  print('Trying manual installation...')
  -- Manual fallback installation
  vim.fn.system("mkdir -p " .. vim.fn.shellescape(lazypath))
  vim.fn.system("git clone --depth 1 https://github.com/folke/lazy.nvim.git " .. vim.fn.shellescape(lazypath))
  vim.opt.rtp:prepend(lazypath)
  package.loaded["lazy"] = nil
  ok, lazy = pcall(require, "lazy")
  if not ok then
    print('Failed to load lazy.nvim even after manual installation. Error: ' .. tostring(lazy))
    return
  end
end

-- Plugin configurations
local plugins = {
  -- Essential plugins
  "nvim-lua/plenary.nvim",
  {
    "ctrlpvim/ctrlp.vim",
    lazy = false,  -- Load immediately
    cmd = { "CtrlP", "CtrlPBuffer", "CtrlPMRU", "CtrlPTag" },
    keys = {
      { "<leader>ff", "<cmd>CtrlP<cr>", desc = "Find files" },
      { "<leader>fb", "<cmd>CtrlPBuffer<cr>", desc = "Buffers" },
      { "<leader>fm", "<cmd>CtrlPMRU<cr>", desc = "Most Recently Used" },
      { "<leader>ft", "<cmd>CtrlPTag<cr>", desc = "Tags" },
      { "<c-p>", "<cmd>CtrlP<cr>", desc = "CtrlP" },
    },
    init = function()
      -- CtrlP settings
      vim.g.ctrlp_map = '<c-p>'
      vim.g.ctrlp_cmd = 'CtrlP'
      vim.g.ctrlp_working_path_mode = 'ra'
      vim.g.ctrlp_show_hidden = 1
      vim.g.ctrlp_max_files = 20000
      vim.g.ctrlp_max_depth = 40

      -- Use ripgrep if available
      if vim.fn.executable('rg') == 1 then
        vim.g.ctrlp_user_command = 'rg --files %s'
        vim.g.ctrlp_use_caching = 0
      end

      -- Ignore common directories
      vim.g.ctrlp_custom_ignore = {
        dir = '\\.git$\\|\\.cache$\\|\\.local$\\|node_modules$\\|target$\\|\\.build$',
        file = '\\.so$\\|\\.swp$\\|\\.zip$\\|\\.pyc$'
      }

      -- Custom key mappings for CtrlP
      vim.g.ctrlp_prompt_mappings = {
        -- Insert mode mappings
        ['<C-j>'] = {'<Down>'},
        ['<C-k>'] = {'<Up>'},
        ['<Tab>'] = {'<Down>'},
        ['<S-Tab>'] = {'<Up>'},
        ['<CR>'] = {'<C-y>'},  -- Accept selection and close
        ['<Esc>'] = {'<C-c>'},
        ['<C-c>'] = {'<C-c>'},

        -- Normal mode mappings
        ['<C-j>'] = {'<Down>'},
        ['<C-k>'] = {'<Up>'},
        ['<Tab>'] = {'<Down>'},
        ['<S-Tab>'] = {'<Up>'},
        ['<CR>'] = {'<C-y>'},
        ['q'] = {'<C-c>'},
        ['<Esc>'] = {'<C-c>'},

        -- Additional useful mappings
        ['<C-x>'] = {'<C-s>'},  -- Open in horizontal split
        ['<C-v>'] = {'<C-v>'},  -- Open in vertical split
        ['<C-t>'] = {'<C-t>'},  -- Open in new tab
      }

      -- Ensure CtrlP starts in insert mode
      vim.g.ctrlp_insert_mode = 1
    end,
    config = function()
      -- CtrlP configured silently
    end,
  },

  -- Telescope fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    tag = '0.1.8',
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      { "<leader>fr", "<cmd>Telescope oldfiles cwd_only=true<cr>", desc = "Recent files (cwd)" },
      { "<leader>fc", "<cmd>Telescope commands<cr>", desc = "Commands" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
      { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
      { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    },
    config = function()
      local telescope = require('telescope')
      local actions = require('telescope.actions')

      telescope.setup({
        defaults = {
          -- 検索結果のソート改善
          sorting_strategy = "ascending",
          file_sorter = require('telescope.sorters').get_fuzzy_file,
          generic_sorter = require('telescope.sorters').get_generic_fuzzy_sorter,

          -- プロンプトを上部に
          layout_strategy = "horizontal",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.55,
              results_width = 0.8,
            },
            vertical = {
              mirror = false,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 1,  -- Always show preview
          },

          -- 色とアイコンの改善
          borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },

          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-n>"] = actions.cycle_history_next,
              ["<C-p>"] = actions.cycle_history_prev,
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
              ["<Esc>"] = actions.close,
              ["<C-c>"] = actions.close,
              -- プレビューのスクロール
              ["<C-u>"] = actions.preview_scrolling_up,
              ["<C-d>"] = actions.preview_scrolling_down,
              -- 選択モード
              ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
              ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
            },
            n = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["q"] = actions.close,
              ["<Esc>"] = actions.close,
              -- プレビューのスクロール
              ["<C-u>"] = actions.preview_scrolling_up,
              ["<C-d>"] = actions.preview_scrolling_down,
              -- 選択モード
              ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
              ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
            },
          },

          -- パフォーマンス改善
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",  -- 隠しファイルも検索
            "--glob=!.git/",  -- .gitディレクトリは除外
          },

          file_ignore_patterns = {
            "node_modules",
            ".git/",
            "%.lock",
            "target/",
            "build/",
            "dist/",
            "%.jpg",
            "%.png",
            "%.jpeg",
            "%.gif",
            "%.svg",
            "%.ico",
          },

          -- 検索結果の表示改善
          path_display = { "truncate" },  -- 長いパスを省略
          set_env = { ["COLORTERM"] = "truecolor" },
        },

        pickers = {
          find_files = {
            hidden = true,
            follow = true,  -- シンボリックリンクを追跡
            find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
          },
          oldfiles = {
            cwd_only = true,
            only_cwd = true,
          },
          live_grep = {
            additional_args = function()
              return { "--hidden", "--glob=!.git/" }
            end,
          },
          buffers = {
            sort_mru = true,  -- 最近使用順にソート
            ignore_current_buffer = true,
          },
        },
      })

      -- Load fzf native extension for better performance
      pcall(telescope.load_extension, 'fzf')
    end,
  },

  -- UI and theme
  "tomasr/molokai",
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "NvimTreeToggle", "NvimTreeOpen" },
  },
  "nvim-tree/nvim-web-devicons",

  -- Git integration
  "tpope/vim-fugitive",
  "airblade/vim-gitgutter",

  -- Status line
  "itchyny/lightline.vim",

  -- Navigation and utilities
  "majutsushi/tagbar",
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
  },

  -- Language specific
  "github/copilot.vim",

  -- React/JavaScript/TypeScript specific
  {
    "maxmellon/vim-jsx-pretty",
    ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  },
  {
    "HerringtonDarkholme/yats.vim",
    ft = { "typescript", "typescriptreact" },
  },
  {
    "styled-components/vim-styled-components",
    ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  },
  {
    "mattn/emmet-vim",
    ft = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact" },
    config = function()
      vim.g.user_emmet_leader_key = '<C-y>'
      vim.g.user_emmet_settings = {
        javascript = {
          extends = 'jsx',
        },
        typescript = {
          extends = 'tsx',
        },
      }
    end,
  },

  -- Color highlighting and preview
  {
    "norcalli/nvim-colorizer.lua",
    lazy = false,
    config = function()
      require('colorizer').setup({
        '*', -- Enable for all filetypes
      }, {
        RGB = true, -- #RGB hex codes
        RRGGBB = true, -- #RRGGBB hex codes
        names = false, -- "Name" codes like Blue or red
        RRGGBBAA = false, -- #RRGGBBAA hex codes
        rgb_fn = true, -- CSS rgb() and rgba() functions
        hsl_fn = true, -- CSS hsl() and hsla() functions
        css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
        css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
        mode = 'background', -- Set the display mode.
        tailwind = 'both', -- Enable tailwind colors
      })

      -- Start colorizer automatically
      vim.cmd('ColorizerReloadAllBuffers')
    end,
  },
  {
    "themaxmarchuk/tailwindcss-colors.nvim",
    config = function()
      require("tailwindcss-colors").setup()
    end
  },

  -- LSP and completion
  "neovim/nvim-lspconfig",
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim", "nvim-lspconfig" },
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
  },
}

-- Setup lazy.nvim
lazy.setup(plugins, {
  install = {
    colorscheme = { "molokai" },
  },
  checker = {
    enabled = true,
    notify = false,  -- Don't show update notifications on startup
  },
  rocks = {
    enabled = false,  -- Disable luarocks support (not needed for current plugins)
  },
  ui = {
    backdrop = 100,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

return true