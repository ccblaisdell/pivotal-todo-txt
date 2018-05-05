require 'test/unit'
require './lib/todo/reconciler.rb'
require 'pry'
include TodoReconciler

DEFAULT_SCALE = [0,1,2,3,5,8]

class TodoReconcilerTest < Test::Unit::TestCase  
  def test_update_current_state
    changeset = add_local_changeset({
      "local"    => { "current_state" => "unstarted" },
      "remote"   => { "current_state" => "unstarted" },
      "previous" => { "current_state" => "unstarted" },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal nil, changeset["current_state"]
    
    changeset = add_local_changeset({
      "local"    => { "current_state" => "unstarted" },
      "remote"   => { "current_state" => "unstarted" },
      "previous" => nil,
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal nil, changeset["current_state"]

    changeset = add_local_changeset({
      "local"    => { "current_state" => "started" },
      "remote"   => { "current_state" => "unstarted" },
      "previous" => nil,
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal "started", changeset["current_state"]

    changeset = add_local_changeset({
      "local"    => { "current_state" => "started" },
      "remote"   => { "current_state" => "unstarted" },
      "previous" => nil,
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal "started", changeset["current_state"]

    changeset = add_local_changeset({
      "local"    => { "current_state" => "unstarted" },
      "remote"   => { "current_state" => "started" },
      "previous" => nil,
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal "started", changeset["current_state"]

    changeset = add_local_changeset({
      "local"    => { "current_state" => "unstarted" },
      "remote"   => { "current_state" => "started" },
      "previous" => { "current_state" => "started" },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal "unstarted", changeset["current_state"]
  end

  def test_update_estimate
    # nothing changed
    changeset = add_local_changeset({
      "local"    => { "estimate" => 1 },
      "remote"   => { "estimate" => 1 },
      "previous" => { "estimate" => 1 },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal nil, changeset["estimate"]

    # local and remote agree
    changeset = add_local_changeset({
      "local"    => { "estimate" => 1 },
      "remote"   => { "estimate" => 1 },
      "previous" => { "estimate" => 0 },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal 1, changeset["estimate"]

    # only local changed
    changeset = add_local_changeset({
      "local"    => { "estimate" => 1 },
      "remote"   => { "estimate" => nil },
      "previous" => { "estimate" => nil },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal 1, changeset["estimate"]

    # only remote changed
    changeset = add_local_changeset({
      "local"    => { "estimate" => nil },
      "remote"   => { "estimate" => 0 },
      "previous" => { "estimate" => nil },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal 0, changeset["estimate"]

    # local and remote have diverged
    changeset = add_local_changeset({
      "local"    => { "estimate" => 1 },
      "remote"   => { "estimate" => 2 },
      "previous" => nil,
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal 2, changeset["estimate"]
  end

  def test_enforce_min_estimate_if_start
    changeset = add_local_changeset({
      "local"    => { "estimate" => nil, "current_state" => "started", "story_type" => "feature" },
      "remote"   => { "estimate" => nil },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal 1, changeset["estimate"]

    # Should not enforce estimate for non-features
    changeset = add_local_changeset({
      "local"    => { "estimate" => nil, "current_state" => "started", "story_type" => "chore" },
      "remote"   => { "estimate" => nil },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal nil, changeset["estimate"]
  end

  def test_update_name
    # nothing changed
    changeset = add_local_changeset({
      "local"    => { "name" => "name" },
      "remote"   => { "name" => "name" },
      "previous" => { "name" => "name" },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal nil, changeset["name"]

    # local and remote agree
    changeset = add_local_changeset({
      "local"    => { "name" => "changed" },
      "remote"   => { "name" => "changed" },
      "previous" => { "name" => "name" },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal "changed", changeset["name"]
  end

  def test_clamp_estimate
    changeset = add_local_changeset({
      "local"  => { "estimate" => 0 },
      "remote" => { "esimate" => nil },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal 0, changeset["estimate"]

    changeset = add_local_changeset({
      "local"  => { "estimate" => 1 },
      "remote" => { "esimate" => nil },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal 1, changeset["estimate"]

    changeset = add_local_changeset({
      "local"  => { "estimate" => 2 },
      "remote" => { "esimate" => nil },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal 2, changeset["estimate"]

    changeset = add_local_changeset({
      "local"  => { "estimate" => 4 },
      "remote" => { "esimate" => nil },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal 5, changeset["estimate"]

    changeset = add_local_changeset({
      "local"  => { "estimate" => 5 },
      "remote" => { "esimate" => nil },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal 5, changeset["estimate"]

    changeset = add_local_changeset({
      "local"  => { "estimate" => 8 },
      "remote" => { "esimate" => nil },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal 8, changeset["estimate"]

    changeset = add_local_changeset({
      "local"  => { "estimate" => 9 },
      "remote" => { "esimate" => nil },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal 8, changeset["estimate"]

    changeset = add_local_changeset({
      "local"  => { "estimate" => 99 },
      "remote" => { "esimate" => nil },
    }, DEFAULT_SCALE)["local_changeset"]
    assert_equal 8, changeset["estimate"]
  end
end