require './lib/todo/reconciler'

module PivotalReconciler
  module_function

  def add_remote_changeset(task)
    local = task["local"] || {}
    remote = task["remote"]

    changeset = {}
    changeset = update_current_state(changeset, local, remote)
    changeset = enforce_min_estimate_if_start(changeset, local, remote)
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
    elsif local[name].nil?
      changeset
    else
      changeset.merge({ name => local[name] })
    end
  end

  def update_current_state(changeset, local, remote)
    if local.nil? || remote.nil?
      changeset
    elsif local["current_state"] == remote["current_state"]
      changeset
    elsif TodoReconciler.state_val(local) == TodoReconciler.state_val(remote)
      changeset
    else
      changeset.merge({ "current_state" => local["current_state"] })
    end
  end

  def enforce_min_estimate_if_start(changeset, local, remote)
    if local["story_type"] != "feature"
      changeset
    elsif local["estimate"].nil? && changeset["estimate"].nil? && TodoReconciler.state_val(local) > 0
      changeset.merge({ "estimate" => 1 })
    else
      changeset
    end
  end
end