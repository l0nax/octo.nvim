require("octo.host.host")

local prov = require("octo.host.helper")



local M = {
   util = {},
}
local provider

local function notify(msg, kind)
   vim.notify(msg, kind, { title = "Octo.nvim" })
end

function M:set_provider(hostname)
   local p = prov.resolve(hostname)
   if not p then
      notify("Unable to resolve provider for hostname " .. hostname, 2)
      return
   end

   provider = p
end

function M:list_issues(repo, filter, cb)
   M:set_provider(repo.hostname)
   provider:list_issues(repo, filter, cb)
end

function M:get_issue(repo, number, cb)
   provider:get_issue(repo, number, cb)
end

function M:get_user_name()
   return provider:get_user_name()
end

function M:process_issues(opts, output)

   return provider:process_issues(opts, output)
end

function M.util:get_filter(opts, kind)
   return provider.util:get_filter(opts, kind)
end

return M
