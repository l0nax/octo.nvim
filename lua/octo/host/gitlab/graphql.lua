local M = {}

-- NOTE: Filters, like the one working for GitHub do NOT work 1:1 for GitLab!!
-- I. e., you can write: filterBy: { assignee: "USERNAME" }
-- this request would be an extra field for GitLab!!
M.issues_query = [[
query($endCursor: String) {
  project(fullPath: "%s") {
    issues(first: 100, after: $endCursor, %s) {
      nodes {
        __typename
        iid
        title
        webUrl
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
]]

local function escape_chars(str)
  local escaped, _ = string.gsub(str, '["\\]', {
    ['"'] = '\\"',
    ["\\"] = "\\\\",
  })
  return escaped
end

local I = {}

function I.g(query, ...)
  local opts = { escape = true }
  for _, v in ipairs { ... } do
    if type(v) == "table" then
      opts = vim.tbl_deep_extend("force", opts, v)
      break
    end
  end
  local escaped = {}
  for _, v in ipairs { ... } do
    if type(v) == "string" and opts.escape then
      local encoded = escape_chars(v)
      table.insert(escaped, encoded)
    else
      table.insert(escaped, v)
    end
  end
  return string.format(M[query], unpack(escaped))
end

return I
