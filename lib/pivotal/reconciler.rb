module PivotalReconciler
  module_function

  def add_remote_changeset(task)
    local = task["local"] || {}
    remote = task["remote"]

    changeset = {}
    changeset = update("current_state", changeset, local, remote)
    changeset = update("estimate", changeset, local, remote)
    changeset = update("name", changeset, local, remote)
    changeset = changeset.empty? ? nil : changeset.merge({ "id" => remote["id"] })
    
    task["remote_changeset"] = changeset
    task
  end

  def update(name, changeset, local, remote)
    if local.nil? or remote.nil?
      changeset
    elsif local[name] == remote[name]
      changeset
    else
      changeset.merge({ name => local[name] })
    end
  end
end