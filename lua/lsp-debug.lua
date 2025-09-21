-- LSP Debug Helper
-- Usage: :lua require('lsp-debug').check_lsp()

local M = {}

function M.check_lsp()
  print("=== LSP Debug Information ===")

  -- Check Neovim version
  local nvim_version = vim.version()
  print("Neovim version: " .. nvim_version.major .. "." .. nvim_version.minor .. "." .. nvim_version.patch)

  local use_new_api = nvim_version.major > 0 or (nvim_version.major == 0 and nvim_version.minor >= 11)
  print("Using new API: " .. tostring(use_new_api))

  -- Check active LSP clients
  local clients = vim.lsp.get_clients()
  print("\nActive LSP clients: " .. #clients)
  for _, client in ipairs(clients) do
    print("  - " .. client.name .. " (ID: " .. client.id .. ")")
  end

  -- Check buffer LSP clients
  local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
  print("\nBuffer LSP clients: " .. #buf_clients)
  for _, client in ipairs(buf_clients) do
    print("  - " .. client.name .. " (ID: " .. client.id .. ")")
  end

  -- Check Mason installed packages
  local mason_registry_ok, mason_registry = pcall(require, 'mason-registry')
  if mason_registry_ok then
    print("\nMason installed packages:")
    local installed = mason_registry.get_installed_packages()
    for _, pkg in ipairs(installed) do
      print("  - " .. pkg.name)
    end
  else
    print("\nMason registry not available")
  end

  -- Check current file type
  print("\nCurrent buffer:")
  print("  - Filetype: " .. vim.bo.filetype)
  print("  - Filename: " .. vim.fn.expand('%:t'))

  -- Check LSP capabilities
  if #buf_clients > 0 then
    print("\nLSP capabilities:")
    for _, client in ipairs(buf_clients) do
      print("  Client: " .. client.name)
      if client.server_capabilities.completionProvider then
        print("    - Completion: ✓")
      else
        print("    - Completion: ✗")
      end
      if client.server_capabilities.hoverProvider then
        print("    - Hover: ✓")
      else
        print("    - Hover: ✗")
      end
    end
  end
end

return M