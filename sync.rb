#!/usr/bin/env ruby
require 'dotenv/load'
require './lib/pivotal/api'
require './lib/pivotal/parser'
require './lib/pivotal/serializer'
require './lib/todo/parser'

FILE_NAME = "todo.txt.md"

# eventual usage
# ruby pivotal-todo-txt --watch --file ~/dev/icmib/todo.md

module Sync
  module_function

  CURRENT_STATE_VALUE = {
    nil => -1,
    "unscheduled" => 0,
    "planned" => 0,
    "unstarted" => 0,
    "started" => 2,
    "finished" => 3,
    "delivered" => 3,
    "accepted" => 3,
    "rejected" => 6,
  }

  def start
    owners = PivotalApi.fetch_owners
    labels = PivotalApi.fetch_labels
    epics = PivotalApi.fetch_epics
    
    my_remote_stories = PivotalApi.fetch_my_stories
    support_remote_stories = PivotalApi.fetch_support_stories
    remote_stories = PivotalParser.parse_all(my_remote_stories + support_remote_stories)

    local_lines_and_tasks = read(owners)
    local_tasks = local_lines_and_tasks.select {|l| l.is_a?(Hash)}.select {|t| !t["id"].nil?}
    
    # compare stuff

    new_lines_and_tasks = local_lines_and_tasks
    
    advance_current_state_of_remote_stories(new_lines_and_tasks, remote_stories)
    new_lines_and_tasks = create_new_remote_stories(new_lines_and_tasks)

    new_lines_and_tasks = advance_current_state_of_local_tasks(new_lines_and_tasks, remote_stories)
    new_lines_and_tasks = get_new_local_tasks(remote_stories, local_tasks) + new_lines_and_tasks

    write(new_lines_and_tasks, owners)
  end

  def rebuild
    owners = PivotalApi.fetch_owners
    labels = PivotalApi.fetch_labels
    epics = PivotalApi.fetch_epics
    
    my_remote_stories = PivotalApi.fetch_my_stories
    support_remote_stories = PivotalApi.fetch_support_stories
    remote_stories = PivotalParser.parse_all(my_remote_stories + support_remote_stories)

    write(remote_stories, owners)
  end

  def write(lines, owners)
    File.open(FILE_NAME, "w") do |f|
      lines.each do |line| 
        if line.is_a?(Hash)
          f.puts PivotalSerializer.serialize_one(line, owners)
        else
          f.puts line
        end
      end
    end
  end

  # This should gather ALL lines, not just tasks
  def read(owners)
    lines = []
    File.open(FILE_NAME).read.each_line do |line|
      if line.match(/^(-|\+|\*)/)
        lines << TodoParser.parse_one(line, owners)
      else
        lines << line
      end
    end
    lines
  end

  # This is super ugly, but early returns weren't working for some reason
  def create_new_remote_stories(lines)
    lines.map do |line|
      line.is_a?(Hash) && line["id"].nil? ? (
        response = PivotalApi.create_story(line)
        PivotalParser.parse_one(response)
      ) : line
    end
  end

  def get_new_local_tasks(remote_stories, local_tasks)
    new_ids = remote_stories.map {|s| s["id"]} - local_tasks.map {|t| t["id"]}
    new_tasks = remote_stories.select {|story| new_ids.include?(story["id"])}
    new_tasks.empty? ? [] : new_tasks + ["\n"]
  end

  def advance_current_state_of_remote_stories(new_lines_and_tasks, remote_stories)
    new_lines_and_tasks.map do |line|
      line.is_a?(Hash) && line["id"] ? (
        local_task = line
        remote_story = remote_stories.find {|story| story["id"] == local_task["id"]}   
        if current_state_has_advanced?(remote_story, local_task)
          PivotalApi.update_story({ 
            "id" => local_task["id"], 
            "current_state" => local_task["current_state"],
            ("estimate" => 1 if remote_story["estimate"].nil?)
          })
          local_task
        else
          local_task
        end
      ) : line
    end
  end

  def current_state_has_advanced?(from, to)
    CURRENT_STATE_VALUE[to["current_state"]] - CURRENT_STATE_VALUE[from["current_state"]] > 0
  end

  def advance_current_state_of_local_tasks(new_lines_and_tasks, remote_stories)
    new_lines_and_tasks.map do |line|
      line.is_a?(Hash) && line["id"] ? (
        local_task = line
        remote_story = remote_story = remote_stories.find {|story| story["id"] == local_task["id"]}   
        if current_state_has_advanced?(local_task, remote_story)
          local_task["current_state"] = remote_story["current_state"]
          local_task
        else
          line
        end
      ) : line
    end
  end
end

include Sync
Sync.start
