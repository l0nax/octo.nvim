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
  -- Is the repository the issue belongs to.
  repo: Repository

  -- Is the ID of the Issue within the repository/ project.
  id: integer
  title: string
end
