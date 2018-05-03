module PivotalReconciler
  module_function

  def add_remote_changeset(task)
    local = task["local"] || {}
    remote = task["remote"]

    changeset = { "id" => remote["id"] }
    changeset = update("current_state", changeset, local, remote)
    changeset = update("estimate", changeset, local, remote)
    changeset = update("name", changeset, local, remote)
    
    task["remote_changeset"] = changeset
    task
  end

  def update(name, changeset, local, remote)
    local[name] == remote[name] ?
      changeset :
      changeset.merge({ name => local[name] })
  end
end