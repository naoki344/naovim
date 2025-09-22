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
      print('CtrlP setup completed')
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
  {
    "fatih/vim-go",
    ft = "go",
  },
  "github/copilot.vim",

  -- Color highlighting and preview
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require('colorizer').setup({
        '*', -- Highlight all files, but customize some others.
        css = { rgb_fn = true }, -- Enable parsing rgb(...) functions in css.
        html = { names = false }, -- Disable parsing "names" like Blue or Gray
      }, {
        RGB = true, -- #RGB hex codes
        RRGGBB = true, -- #RRGGBB hex codes
        names = true, -- "Name" codes like Blue or red
        RRGGBBAA = false, -- #RRGGBBAA hex codes
        AARRGGBB = false, -- 0xAARRGGBB hex codes
        rgb_fn = true, -- CSS rgb() and rgba() functions
        hsl_fn = true, -- CSS hsl() and hsla() functions
        css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
        css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
        mode = 'background', -- Set the display mode.
        tailwind = true, -- Enable tailwind colors
      })
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

print('lazy.nvim setup completed')
return true