local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; require("octo.def_G")
require("octo.model.octo")

local BOctoBuffer = require("octo.model.octo-buffer").OctoBuffer

local signs = require("octo.signs")

local config = require("octo.config")
local utils = require("octo.utils")



local reviews = require("octo.reviews")
require("octo.completion")
require("octo.folds")

local MT = {}










local M = {}

function M.setup(user_config)
   signs.setup()
   config.setup(user_config or {})
end

function M.configure_octo_buffer(bufnr)
   bufnr = bufnr or vim.api.nvim_get_current_buf()
   local split, path = utils.get_split_and_path(bufnr)
   local buffer = octo_buffers[bufnr]
   if split and path then

      local current_review = reviews.get_current_review()
      if current_review and #current_review.threads > 0 then
         current_review.layout:cur_file():place_signs()
      end
   elseif buffer then

      buffer:configure()
   end
end

function M.save_buffer()
   local bufnr = vim.api.nvim_get_current_buf()
   local buffer = octo_buffers[bufnr]
   buffer:save()
end

function M.load_buffer(bufnr)
   bufnr = bufnr or vim.api.nvim_get_current_buf()
   local bufname = vim.fn.bufname(bufnr)
   local repo, kind, number = string.match(bufname, "octo://(.+)/(.+)/(%d+)")
   if not repo then
      repo = string.match(bufname, "octo://(.+)/repo")
      if repo then
         kind = "repo"
      end
   end
   if (kind == "issue" or kind == "pull") and not repo and not number then
      vim.api.nvim_err_writeln("Incorrect buffer: " .. bufname)
      return
   elseif kind == "repo" and not repo then
      vim.api.nvim_err_writeln("Incorrect buffer: " .. bufname)
      return
   end
   M.load(repo, kind, number, function(obj)
      M.create_buffer(kind, obj, repo, false)
   end)
end

function M.load(repo, kind, number, cb)
   local _ = repo
   local _ = kind
   local _ = number
   local _ = cb































end

function M.render_signcolumn()
   local bufnr = vim.api.nvim_get_current_buf()
   local buffer = octo_buffers[bufnr]
   buffer:render_signcolumn()
end

function M.on_cursor_hold()




































































































end

function M.create_buffer(kind, obj, repo, create)





   local OObj = {}



   local oobj = obj

   local bufnr
   if create then
      bufnr = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_set_current_buf(bufnr)
      vim.cmd(string.format("file octo://%s/%s/%d", repo, kind, oobj.number))
   else
      bufnr = vim.api.nvim_get_current_buf()
   end

   local octo_buffer = BOctoBuffer:new({
      bufnr = bufnr,
      number = oobj.number,
      repo = repo,
      node = obj,
   })

   octo_buffer:configure()
   if kind == "repo" then
      octo_buffer:render_repo()
   else
      octo_buffer:render_issue()
      octo_buffer:async_fetch_taggable_users()
      octo_buffer:async_fetch_issues()
   end
end



















return M
