module TodoReconciler
  module_function

  CURRENT_STATE_VALUE = {
    nil => -1,
    "unscheduled" => 0,
    "planned" => 0,
    "unstarted" => 0,
    "started" => 2,
    "finished" => 3,
    "delivered" => 4,
    "accepted" => 5,
    "rejected" => 6,
  }

  def add_local_changeset(task)
    local = task["local"] || {}
    remote = task["remote"] || {}
    previous = task["previous"]

    changeset = {}
    changeset = update_current_state(changeset, local, remote, previous)
    changeset = update_estimate(changeset, local, remote, previous)
    changeset = enforce_min_estimate_if_start(changeset, local, remote, previous)
    changeset = update_name(changeset, local, remote, previous)

    task["local_changeset"] = changeset
    task
  end

  def enforce_min_estimate_if_start(changeset, local, remote, previous)
    local["estimate"]
    changeset["estimate"]
    if local["estimate"].nil? && changeset["estimate"].nil? && state_val(local) > 0
      changeset.merge({ "estimate" => 1 })
    else
      changeset
    end
  end

  def update_name(changeset, local, remote, previous)
    compare = lambda {|loc, rem| rem} # prefer remote if conflict
    new_name = get_new_val("name", local, remote, previous, &compare)
    new_name.nil? ? changeset : changeset.merge({ "name" => new_name })
  end

  def update_estimate(changeset, local, remote, previous)
    compare = lambda { |a, b| a > b ? a : b } # prefer higher estimate
    new_estimate = get_new_val("estimate", local, remote, previous, &compare)
    new_estimate.nil? ? changeset : changeset.merge({ "estimate" => new_estimate })
  end

  def vals(name, local, remote, previous)
    [ val(local, name), val(remote, name), val(previous, name) ]
  end

  def val(task, name)
    task.nil? ? nil : task[name]
  end

  def get_new_val(name, local, remote, previous, &fn)
    loc, rem, pre = vals(name, local, remote, previous)
    # if nothing changed
    if pre == loc && pre == rem
      nil
    # if local and remote agree
    elsif loc == rem
      loc
    # if only local changed
    elsif pre != loc && pre == rem
      loc
    # if only remote changed
    elsif pre == loc && pre != rem
      rem
    # local and remote have diverged
    else
      fn.call(loc, rem)
    end
  end

  def update_current_state(changeset, local, remote, previous)
    new_state = get_new_current_state(local, remote, previous)
    new_state.nil? ? changeset : changeset.merge({ "current_state" => new_state })
  end

  def get_new_current_state(local, remote, previous)
    prev_to_local = compare_current_state(previous, local)
    prev_to_remote = compare_current_state(previous, remote)
    local_to_remote = compare_current_state(local, remote)

    # nothing has changed
    if prev_to_local.nil? && prev_to_remote.nil? && local_to_remote.nil?
      nil
    # both local and remote have diverged from prev, prefer highest value
    elsif !prev_to_local.nil? && !prev_to_remote.nil?
      local_to_remote > 0 ? remote["current_state"] : local["current_state"]
    # only local has diverged
    elsif !prev_to_local.nil?
      local["current_state"]
    # only remote has diverged
    elsif !prev_to_remote.nil?
      remote["current_state"]
    # prefer highest value
    else
      local_to_remote > 0 ? remote["current_state"] : local["current_state"]
    end
  end

  def compare_current_state(from, to)
    return nil if from.nil?
    return -1 if to.nil?
    return nil if from["current_state"] == to["current_state"]
    state_val(to) - state_val(from)
  end

  def state_val(task)
    CURRENT_STATE_VALUE[task["current_state"]]
  end
end