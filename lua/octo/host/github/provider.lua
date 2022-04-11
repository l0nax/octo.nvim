local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string; require("octo.host.host")
require("octo.model.octo")
local graphql = require("octo.host.github.graphql")
local gh = require("octo.gh")
local utils = require("octo.utils")

local GitHubIssuesQuery = {Data = {Repository = {Node = {GitHubIssue = {}, }, }, }, }
















local GitHubUser = {}



local GitHubReactionGroup = {Users = {}, }





















local GitHubIssueQuery = {Data = {Project = {GitLabIssue = {UserNode = {}, TimelineItems = {}, LabelNode = {GitLabLabel = {}, }, }, }, }, }






























































local function convertToUser(u)
   local user = {}
   user.username = u.login

   return user
end

local function convertToUsers(u)
   local users = {}

   for i, user in ipairs(u) do
      users[i] = {}
      users[i].username = user.login
   end

   return users
end

local M = {
   util = {},
}

function M:get_user_name()
   return gh.get_user_name()
end

function M:list_issues(repo, filter, cb)
   if filter == nil then
      filter = ""
   end

   local query = graphql.g("issues_query", repo.owner, repo.name, filter, { escape = false })
   gh.run({
      args = { "api", "graphql", "--paginate", "--jq", ".", "-f", string.format("query=%s", query) },
      cb = cb,
   })
end

function M:get_issue(repo, number, cb)
   local query = graphql.g("issue_query", repo.owner, repo.name, number)
   gh.run({
      args = { "api", "graphql", "--paginate", "--jq", ".", "-f", string.format("query=%s", query) },
      cb = function(output, stderr)
         if stderr and not utils.is_blank(stderr) then
            cb(nil, stderr)
            return
         end

         local result = vim.fn.json_decode(output)
         local obj = result.data.repository.issue
         local issue = {}

         issue.title = obj.title
         issue.author = convertToUser(obj.author)
         issue.participants = convertToUsers(obj.participants.nodes)
         issue.milestone = obj.milestone
         issue.createdAt = obj.createdAt
         issue.updatedAt = obj.updatedAt
         issue.closedAt = obj.closedAt
         issue.description = obj.body
         issue.viewerDidAuthor = obj.viewerDidAuthor
         issue.viewerCanUpdate = obj.viewerCanUpdate
         issue.state = obj.state
         issue.reactionGroups = obj.reactionGroups

         issue.assignees = {}
         if obj.assignees and #obj.assignees.nodes > 0 then
            for i, assignee in ipairs(obj.assignees.nodes) do
               issue.assignees[i] = convertToUser(assignee)
            end
         end

         issue.labels = {}
         if obj.labels and #obj.labels.nodes > 0 then
            for i, label in ipairs(obj.labels.nodes) do
               issue.labels[i] = label
            end
         end

         issue.timelineItems = {}
         if obj.timelineItems and #obj.timelineItems.nodes > 0 then
            for i, item in ipairs(obj.timelineItems.nodes) do
               issue.timelineItems[i] = item
               issue.timelineItems[i].itemType = item.__typename
            end
         end

         cb(issue, stderr)
      end,
   })
end

function M:process_issues(opts, output)
   local resp = utils.aggregate_pages(output, "data.repository.issues.nodes")
   local issues = resp.data.repository.issues.nodes
   if #issues == 0 then
      utils.notify(string.format("There are no matching issues in %s.", opts.repo), 2)
      return
   end

   local max_number = -1
   local ret = {}
   for i, issue in ipairs(issues) do
      if #tostring(issue.number) > max_number then
         max_number = #tostring(issue.number)
      end

      ret[i] = {}
      ret[i].__typename = "Issue"
      ret[i].repo = opts.repo
      ret[i].id = issue.number
      ret[i].title = issue.title
   end

   opts.preview_title = opts.preview_title or ""
   opts.prompt_title = opts.prompt_title or ""
   opts.results_title = opts.results_title or ""

   return ret, max_number
end

function M.util:get_filter(opts, kind)
   local filter = ""
   local allowed_values = {}
   if kind == "issue" then
      allowed_values = { "since", "createdBy", "assignee", "mentioned", "labels", "milestone", "states" }
   elseif kind == "pull_request" then
      allowed_values = { "baseRefName", "headRefName", "labels", "states" }
   end

   for _, value in ipairs(allowed_values) do
      if opts[value] then
         local val
         if #vim.split(opts[value], ",") > 1 then

            val = vim.split(opts[value], ",")
         else

            val = opts[value]
         end
         val = vim.fn.json_encode(val)
         val = string.gsub(val, '"OPEN"', "OPEN")
         val = string.gsub(val, '"CLOSED"', "CLOSED")
         val = string.gsub(val, '"MERGED"', "MERGED")
         filter = filter .. value .. ":" .. (val) .. ","
      end
   end

   return filter
end

return M
