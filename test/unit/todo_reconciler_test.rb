require 'test/unit'
require './lib/todo/reconciler.rb'
include TodoReconciler

class TodoReconcilerTest < Test::Unit::TestCase  
  def test_update_current_state
    changeset = add_local_changeset({
      "local"    => { "current_state" => "unstarted" },
      "remote"   => { "current_state" => "unstarted" },
      "previous" => { "current_state" => "unstarted" },
    })["local_changeset"]
    assert_equal nil, changeset["current_state"]
    
    changeset = add_local_changeset({
      "local"    => { "current_state" => "unstarted" },
      "remote"   => { "current_state" => "unstarted" },
      "previous" => nil,
    })["local_changeset"]
    assert_equal nil, changeset["current_state"]

    changeset = add_local_changeset({
      "local"    => { "current_state" => "started" },
      "remote"   => { "current_state" => "unstarted" },
      "previous" => nil,
    })["local_changeset"]
    assert_equal "started", changeset["current_state"]

    changeset = add_local_changeset({
      "local"    => { "current_state" => "started" },
      "remote"   => { "current_state" => "unstarted" },
      "previous" => nil,
    })["local_changeset"]
    assert_equal "started", changeset["current_state"]

    changeset = add_local_changeset({
      "local"    => { "current_state" => "unstarted" },
      "remote"   => { "current_state" => "started" },
      "previous" => nil,
    })["local_changeset"]
    assert_equal "started", changeset["current_state"]

    changeset = add_local_changeset({
      "local"    => { "current_state" => "unstarted" },
      "remote"   => { "current_state" => "started" },
      "previous" => { "current_state" => "started" },
    })["local_changeset"]
    assert_equal "unstarted", changeset["current_state"]
  end

  def test_update_estimate
    # nothing changed
    changeset = add_local_changeset({
      "local"    => { "estimate" => 1 },
      "remote"   => { "estimate" => 1 },
      "previous" => { "estimate" => 1 },
    })["local_changeset"]
    assert_equal nil, changeset["estimate"]

    # local and remote agree
    changeset = add_local_changeset({
      "local"    => { "estimate" => 1 },
      "remote"   => { "estimate" => 1 },
      "previous" => { "estimate" => 0 },
    })["local_changeset"]
    assert_equal 1, changeset["estimate"]

    # only local changed
    changeset = add_local_changeset({
      "local"    => { "estimate" => 1 },
      "remote"   => { "estimate" => nil },
      "previous" => { "estimate" => nil },
    })["local_changeset"]
    assert_equal 1, changeset["estimate"]

    # only remote changed
    changeset = add_local_changeset({
      "local"    => { "estimate" => nil },
      "remote"   => { "estimate" => 0 },
      "previous" => { "estimate" => nil },
    })["local_changeset"]
    assert_equal 0, changeset["estimate"]

    # local and remote have diverged
    changeset = add_local_changeset({
      "local"    => { "estimate" => 1 },
      "remote"   => { "estimate" => 2 },
      "previous" => nil,
    })["local_changeset"]
    assert_equal 2, changeset["estimate"]
  end

  def test_enforce_min_estimate_if_start
    changeset = add_local_changeset({
      "local"    => { "estimate" => nil, "current_state" => "started" },
      "remote"   => { "estimate" => nil },
      "previous" => nil,
    })["local_changeset"]
    assert_equal 1, changeset["estimate"]
  end

  def test_update_name
    # nothing changed
    changeset = add_local_changeset({
      "local"    => { "name" => "name" },
      "remote"   => { "name" => "name" },
      "previous" => { "name" => "name" },
    })["local_changeset"]
    assert_equal nil, changeset["name"]

    # local and remote agree
    changeset = add_local_changeset({
      "local"    => { "name" => "changed" },
      "remote"   => { "name" => "changed" },
      "previous" => { "name" => "name" },
    })["local_changeset"]
    assert_equal "changed", changeset["name"]
  end
end