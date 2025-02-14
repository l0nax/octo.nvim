local OctoBuffer = require("octo.model.octo-buffer").OctoBuffer
local utils = require "octo.utils"

local M = {}

function M.hide_review_threads()
  -- This function is called from a very broad CursorMoved event
  -- Check if we are in a diff buffer and otherwise return early
  local bufnr = vim.api.nvim_get_current_buf()
  local split, path = utils.get_split_and_path(bufnr)
  if not split or not path then
    return
  end

  local review = require("octo.reviews").get_current_review()
  local file = review.layout:cur_file()
  if not file then
    return
  end

  local alt_buf = file:get_alternative_buf(split)
  local alt_win = file:get_alternative_win(split)
  if vim.api.nvim_win_is_valid(alt_win) and vim.api.nvim_buf_is_valid(alt_buf) then
    local current_alt_bufnr = vim.api.nvim_win_get_buf(alt_win)
    if current_alt_bufnr ~= alt_buf then
      -- if we are not showing the corresponging alternative diff buffer, do so
      vim.api.nvim_win_set_buf(alt_win, alt_buf)
      -- Scroll to trigger the scrollbind and sync the windows. This works more
      -- consistently than calling `:syncbind`.
      vim.cmd [[exec "normal! \<c-y>"]]
    end
  end
end

function M.show_review_threads()
  -- This function is called from a very broad CursorHold event
  -- Check if we are in a diff buffer and otherwise return early
  local bufnr = vim.api.nvim_get_current_buf()
  local split, path = utils.get_split_and_path(bufnr)
  if not split or not path then
    return
  end

  local review = require("octo.reviews").get_current_review()
  local file = review.layout:cur_file()
  if not file then
    return
  end
  local pr = file.pull_request
  local review_level = review:get_level()
  local threads = vim.tbl_values(review.threads)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local threads_at_cursor = {}
  for _, thread in ipairs(threads) do
    if review_level == "PR" and utils.is_thread_placed_in_buffer(thread, bufnr) and thread.startLine == line then
      table.insert(threads_at_cursor, thread)
    elseif review_level == "COMMIT" then
      local commit
      if split == "LEFT" then
        commit = review.layout.left.commit
      else
        commit = review.layout.right.commit
      end
      for _, comment in ipairs(thread.comments.nodes) do
        if commit == comment.originalCommit.oid and thread.originalLine == line then
          table.insert(threads_at_cursor, thread)
          break
        end
      end
    end
  end

  if #threads_at_cursor == 0 then
    return
  end

  review.layout:ensure_layout()
  local alt_win = file:get_alternative_win(split)
  if vim.api.nvim_win_is_valid(alt_win) then
    local thread_buffer = M.create_thread_buffer(threads_at_cursor, pr.repo, pr.number, split, file.path, line)
    if thread_buffer then
      table.insert(file.associated_bufs, thread_buffer.bufnr)
      vim.api.nvim_win_set_buf(alt_win, thread_buffer.bufnr)
      thread_buffer:configure()
      vim.api.nvim_buf_call(thread_buffer.bufnr, function()
        -- TODO: remove first line but only if its empty and if it has no virtualtext
        --vim.cmd [[normal ggdd]]
        pcall(vim.cmd, "normal ]c")
      end)
    end
  end
end

function M.create_thread_buffer(threads, repo, number, side, path, line)
  local current_review = require("octo.reviews").get_current_review()
  if not vim.startswith(path, "/") then
    path = "/" .. path
  end
  local bufname = string.format("octo://%s/review/%s/threads/%s%s:%d", repo, current_review.id, side, path, line)
  local bufnr = vim.fn.bufnr(bufname)
  local buffer
  if bufnr == -1 then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, bufname)
    buffer = OctoBuffer:new {
      bufnr = bufnr,
      number = number,
      repo = repo,
    }
    buffer:render_threads(threads)
    buffer:render_signcolumn()
  elseif vim.api.nvim_buf_is_loaded(bufnr) then
    buffer = octo_buffers[bufnr]
  else
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
  return buffer
end

return M
