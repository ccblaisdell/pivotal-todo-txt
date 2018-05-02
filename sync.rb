#!/usr/bin/env ruby
require 'dotenv/load'
require './lib/pivotal/api'
require './lib/pivotal/parser'
require './lib/pivotal/serializer'
include PivotalApi
include PivotalParser
include PivotalSerializer

FILE_NAME = "todo.txt.md"

module Sync
  def start
    owners = PivotalApi.fetch_owners
    labels = PivotalApi.fetch_labels
    epics = PivotalApi.fetch_epics
    my_remote_stories = PivotalApi.fetch_my_stories
    support_remote_stories = PivotalApi.fetch_support_stories
    remote_stories = PivotalParser.parse_all(my_remote_stories + support_remote_stories)

    write(remote_stories, owners)
    # local_tasks = Todo.fetch_tasks

    # compare stuff
    # tasks_to_update_locally = ...
    # stories_to_update_remotely = ...
    # tasks_to_create_remotely = ...
    # stories_to_create_locally = ...
  end

  def write(stories, owners)
    File.open(FILE_NAME, "w") do |f|
      stories.each do |story| 
        f.puts PivotalSerializer.serialize_one(story, owners)
      end
    end
  end
end

include Sync
Sync.start
