global type Repository = record
  hostname: string

  -- Is the full path of the repository/ project (owner+name).
  full_path: string
  -- The owner name.
  -- For GitLab repositories this would be the full group path
  -- and not only the root group.
  owner: string
  -- Is the name of the repository/ project.
  name: string
  id: integer
end

global type Issue = record
  __typename: string

  -- Is the repository the issue belongs to.
  repo: Repository

  -- Is the ID of the Issue within the repository/ project.
  -- For GitLab repos it's the IID.
  id: integer
  title: string
  author: User
  milestone: Milestone
  createdAt: string
  closedAt: string
  updatedAt: string
  description: string
  state: IssueState
  assignees: {User}
  labels: {Label}
  reactionGroups: {ReactionGroup}

  viewerDidAuthor: boolean
  viewerCanUpdate: boolean
end

global type ReactionGroup = record
end

global type IssueState = enum
  "all"
  "closed"
  "locked"
  "opened"
end

global type User = record
  id: integer
  username: string
  name: string

  -- Special Fields

  isViewer: boolean
end

global type Label = record
  name: string
  color: string
end

global type Milestone = record
  title: string

  enum MilestoneStateEnum
    "active"
    "close"
  end
  state: MilestoneStateEnum
end
