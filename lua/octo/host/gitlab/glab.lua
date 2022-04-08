local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local _, Job = pcall(require, "plenary.job")

local M = {}

local env_vars = {
   PATH = vim.env["PATH"],
   GH_CONFIG_DIR = vim.env["GH_CONFIG_DIR"],
   GITLAB_TOKEN = vim.env["GITLAB_TOKEN"],
   XDG_CONFIG_HOME = vim.env["XDG_CONFIG_HOME"],
   XDG_DATA_HOME = vim.env["XDG_DATA_HOME"],
   XDG_STATE_HOME = vim.env["XDG_STATE_HOME"],
   AppData = vim.env["AppData"],
   LocalAppData = vim.env["LocalAppData"],
   HOME = vim.env["HOME"],
   NO_COLOR = 1,
   http_proxy = vim.env["http_proxy"],
   https_proxy = vim.env["https_proxy"],
}


function M.get_user_name()
   local job = Job:new({
      enable_recording = true,
      command = "glab",
      args = { "auth", "status" },
      env = env_vars,
   })
   job:sync(nil, nil)
   local stderr = table.concat(job:stderr_result(), "\n")
   local name = string.match(stderr, "Logged in to [^%s]+ as ([^%s]+)")
   if name then
      return name
   else
      require("octo.utils").notify(stderr, 2)
   end
end

 RunOpts = {}












function M.run(opts)
   if not Job then
      return
   end


   if not vim.g.octo_viewer then
      vim.g.octo_viewer = M.get_user_name()
   end

   opts = opts or {}
   local mode = opts.mode or "async"
   if opts.args[1] == "api" then
      table.insert(opts.args, "--hostname")
      table.insert(opts.args, opts.hostname)
   end

   if opts.headers then
      for _, header in ipairs(opts.headers) do
         table.insert(opts.args, "-H")
         table.insert(opts.args, header)
      end
   end

   local job = Job:new({
      enable_recording = true,
      command = "glab",
      args = opts.args,
      on_exit = vim.schedule_wrap(function(j_self, _, _)
         if mode == "async" and opts.cb then
            local output = table.concat(j_self:result(), "\n")
            local stderr = table.concat(j_self:stderr_result(), "\n")
            opts.cb(output, stderr)
         end
      end),
      env = env_vars,
   })

   if mode == "sync" then
      job:sync()
      return table.concat(job:result(), "\n"), table.concat(job:stderr_result(), "\n")
   else
      job:start()
   end
end

return M
