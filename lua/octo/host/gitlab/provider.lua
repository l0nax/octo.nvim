local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string; require("octo.host.host")
require("octo.model.octo")
local graphql = require("octo.host.gitlab.graphql")
local glab = require("octo.host.gitlab.glab")
local utils = require("octo.utils")

local GitLabIssuesQuery = {Data = {Project = {Node = {GitLabIssue = {}, }, }, }, }

















local GitLabIssueQuery = {Data = {Project = {GitLabIssue = {UserPermission = {}, UserNode = {}, LabelNode = {GitLabLabel = {}, }, }, }, }, }











































local M = {
   util = {},
}

function M:get_user_name()
   return glab.get_user_name()
end













function M:list_issues(repo, filter, cb)
   if filter == nil then
      filter = ""
   end

   local query = graphql.g("issues_query", repo.full_path, filter, { escape = false })
   glab.run({
      hostname = repo.hostname,
      args = { "api", "graphql", "--paginate", "--jq", ".", "-f", string.format("query=%s", query) },
      cb = cb,
   })
end

function M:get_issue(repo, number, cb)
   local query = graphql.g("issue_query", repo.full_path, number)
   glab.run({
      hostname = repo.hostname,
      args = { "api", "graphql", "--paginate", "--jq", ".", "-f", string.format("query=%s", query) },
      cb = function(output, stderr)
         if stderr and not utils.is_blank(stderr) then
            cb(nil, stderr)
            return
         end

         local result = vim.fn.json_decode(output)
         local obj = result.data.project.issue
         local issue = {}

         issue.title = obj.title
         issue.author = obj.author
         issue.milestone = obj.milestone
         issue.createdAt = obj.createdAt
         issue.updatedAt = obj.updatedAt
         issue.closedAt = obj.closedAt
         issue.description = obj.description
         issue.viewerDidAuthor = false
         issue.viewerCanUpdate = obj.userPermissions.updateIssue or obj.userPermissions.adminIssue
         issue.state = obj.state
         issue.reactionGroups = {}
         issue.url = obj.webUrl

         issue.assignees = {}
         if obj.assignees and #obj.assignees.nodes > 0 then
            for i, assignee in ipairs(obj.assignees.nodes) do
               issue.assignees[i] = assignee
            end
         end

         issue.labels = {}
         if obj.labels and #obj.labels.nodes > 0 then
            for i, label in ipairs(obj.labels.nodes) do
               issue.labels[i] = {}
               issue.labels[i].color = label.textColor
               issue.labels[i].name = label.title
            end
         end

         cb(issue, stderr)
      end,
   })
end

function M:process_issues(opts, output)
   local resp = utils.aggregate_pages(output, "data.project.issues.nodes")
   local issues = resp.data.project.issues.nodes
   if #issues == 0 then
      utils.notify(string.format("There are no matching issues in %s.", opts.repo), 2)
      return
   end

   local max_number = -1
   local ret = {}
   for i, issue in ipairs(issues) do
      if #tostring(issue.iid) > max_number then
         max_number = #tostring(issue.iid)
      end

      ret[i] = {}
      ret[i].__typename = "Issue"
      ret[i].repo = opts.repo
      ret[i].id = issue.iid
      ret[i].title = issue.title
   end

   opts.preview_title = opts.preview_title or ""
   opts.prompt_title = opts.prompt_title or ""
   opts.results_title = opts.results_title or ""

   return ret, max_number
end

function M.util:get_filter(opts, kind)
   local convTarget = {}




   local filter = ""
   local allowed_values = {}
   local map = {}
   if kind == "issue" then
      allowed_values = { "createdAfter", "author", "assignee", "labels", "milestone", "states" }
      map = {
         ["assignee"] = { "assigneeUsernames", "string_array" },
         ["assignees"] = { "assigneeUsernames", "string_array" },
         ["labels"] = { "labelName", "string_array" },
         ["author"] = { "authorUsername", "string" },
         ["milestone"] = { "milestoneTitle", "string" },
         ["states"] = { "state", "string" },
      }
   elseif kind == "pull_request" then

      allowed_values = { "baseRefName", "headRefName", "labels", "states" }
   end

   local hasStateFilter = false

   for _, value in ipairs(allowed_values) do
      if opts[value] then
         local val
         if #vim.split(opts[value], ",") > 1 then

            val = vim.split(opts[value], ",")
         else

            val = opts[value]
         end

         if value == "state" or value == "states" then
            hasStateFilter = true
         end
         if map[value] then
            local target = map[value]
            value = target[1]

            if target[2] == "string_array" then

            end
         end
         val = vim.fn.json_encode(val)
         val = string.gsub(val, '"all"', "all")
         val = string.gsub(val, '"OPEN"', "opened")
         val = string.gsub(val, '"opened"', "opened")
         val = string.gsub(val, '"closed"', "closed")
         val = string.gsub(val, '"locked"', "locked")

         filter = filter .. value .. ":" .. (val) .. ","
      end
   end

   if not hasStateFilter then
      filter = filter .. "state:opened,"
   end

   return filter
end

return M
