local config = require "octo.config"

local providers = config.get_config().git_hosts

local M = {}

function M.resolve(hostname)
  local provider_name = providers[hostname] -- TODO: Error if not defined in map!
  local ok, provider = pcall(require, string.format("octo.host.%s.provider", provider_name))
  if ok then
    notify("Error loading " .. provider_name, 2)
    return provider

  end

  notify("Error loading " .. hostname .. "(" .. provider_name .. ")", 2)
end

function M.notify(msg, kind)
  vim.notify(msg, kind, { title = "Octo.nvim" })
end

return M
