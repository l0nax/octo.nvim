local record OctoBuffer
  bufnr: integer
  number: integer
  repo: string
  kind: string
  -- titleMetadata: TitleMetadata
  -- bodyMetadata: BodyMetadata
  -- commentsMetadata: CommentMetadata[]
  -- threadsMetadata: ThreadMetadata[]
  -- node: table
  -- taggable_users: string[]

  record newOpts
    bufnr: integer
    number: integer
    repo: string
    kind: string
    -- commentsMetadata: CommentMetadata[]
    -- threadsMetadata: ThreadMetadata[]
  end

  new: function(newOpts): OctoBuffer
  apply_mappings: function()
  render_repo: function()
  render_issue: function()
  clear: function()

  -- NOTE: This is used (and defined) in writers.lua!!
  record Threads
    {Threads}

    path: string
    diffSide: string -- TODO: Type?
    originalStartLine: number
    originalLine: number
    isOutdated: boolean
    isResolved: boolean
    isCollapsed: boolean
    comments: any -- TODO: We know that this is an object.
  end
  render_threads: function(threads: Threads)

  configure: function()
  async_fetch_taggable_users: function()
  async_fetch_issues: function()
  save: function()

end

local record M
  OctoBuffer: OctoBuffer

  record Buffer
    titleMetadata: any
    bodyMetadata: any
    node: any -- NOTE: This is an object

    isIssue: function(): boolean
    isPullRequest: function(): boolean
    render_signcolumn: function()
  end
  do_save_title_and_body: function(buffer: Buffer)
end

return M
