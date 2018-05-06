#!/usr/bin/env ruby
require 'dotenv/load'
require 'pry'
require 'listen'
require './lib/pivotal/api'
require './lib/pivotal/parser'
require './lib/pivotal/reconciler'
require './lib/pivotal/serializer'
require './lib/todo/parser'
require './lib/todo/reconciler'

DEFAULT_FILE_NAME = "todo.txt.md"
DEFAULT_SCALE = [0,1,2,3,5,8]

# Optimized for icmib
DEFAULT_IGNORE = [
  /\.cache-loader/,
  /\.sass-cache/,
  /\.storybook/,
  /\.vscode/,
  /app/,
  /bin/,
  /buildpack/,
  /config/,
  /coverage/,
  /data/,
  /db/,
  /doc/,
  /flow-typed/,
  /lib/,
  /node_modules/,
  /public/,
  /script/,
  /test/,
]

class Sync
  def initialize(opts={})
    @file_name = opts[:file] || DEFAULT_FILE_NAME
    @watch = opts[:watch]
    @ignore_next_event = false
    @estimate_scale = DEFAULT_SCALE # ENV['ESTIMATE_SCALE'].split(',').map {|d| d.to_i} || DEFAULT_SCALE
    if @watch
      watch()
    else
      run()
    end
  end

  def watch
    file_name = File.expand_path(@file_name)
    dir = File.dirname(file_name)
    matcher = Regexp.new( Regexp.escape(File.basename(file_name)) )

    @listener = Listen.to(dir, only: matcher, ignore: DEFAULT_IGNORE) do
      if !@ignore_next_event
        run()
      else
        @ignore_next_event = false
      end
    end
    @listener.start

    puts "👀 watching: #{File.expand_path(@file_name)}"

    run
    sleep
    at_exit { @listener.stop }
  end

  def run
    puts "Syncing..."

    # Get remote resources

    owners = PivotalApi.fetch_owners
    labels = PivotalApi.fetch_labels
    my_remote_stories = PivotalApi.fetch_my_stories
    support_remote_stories = PivotalApi.fetch_support_stories
    remote_stories_by_id = PivotalParser
      .parse_all(my_remote_stories + support_remote_stories)
      .group_by {|s| s["id"]}
    
    # Get lines in local file

    @lines = read(owners)

    # Match local tasks with remote stories

    @lines = zip(@lines, remote_stories_by_id)

    # Find remote stories that are not in local file

    @new_remote_stories = find_new_stories(@lines, remote_stories_by_id)
    
    # Reconcile
    
    @lines = add_local_changesets(@lines, @estimate_scale)
    @lines = add_remote_changesets(@lines, @estimate_scale)
    
    # Commit changes
    
    @lines = apply_local_changesets(@lines)
    @lines = create_stories_from_new_local_tasks(@lines, owners)
    @lines = add_new_remote_stories(@lines, @new_remote_stories)
    @ignore_next_event = true
    write(@lines, owners)
    
    apply_remote_changesets(@lines)
    
    puts "Sync complete!"
  end

  def add_new_remote_stories(lines, new_remote_stories)
    new_remote_stories.length > 0 ? new_remote_stories + ["\n"] + lines : lines
  end

  def apply_remote_changesets(lines)
    lines.each do |line|
      if TodoParser.is_task?(line) && !line["remote_changeset"].nil? && !line["remote_changeset"].empty?
        puts "Updating story: ", line["remote_changeset"]
        PivotalApi.update_story(line["remote_changeset"])
      end
    end
  end

  def create_stories_from_new_local_tasks(lines, owners)
    lines.map do |line|
      if TodoParser.is_task?(line) && line["remote"].nil? && line["local"]["id"].nil?
        story = PivotalReconciler.enforce_default_owner(line["local"], ENV['MY_PIVOTAL_INITIALS'], owners)
        puts "Creating story: ", story
        response = PivotalApi.create_story(story)
        task = PivotalParser.parse_one(response)
        line.merge({ "local" => task, "remote" => task })
      else
        line
      end
    end
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
    File.open(@file_name, "w") do |f|
      lines.each do |line| 
        if TodoParser.is_task?(line)
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
    File.open(@file_name, "a+").read.each_line do |line|
      if TodoParser.is_task?(line)
        task = TodoParser.parse_one(line, owners)
        lines << { "local" => task }
      else
        lines << line
      end
    end
    lines
  end

  def zip(lines, remote_stories_by_id)
    lines.map do |line|
      if TodoParser.is_task?(line)
        stories = remote_stories_by_id[ line["local"]["id"] ]
        stories.nil? ? line : line.merge({ "remote" => stories[0] })
      else
        line
      end
    end
  end

  def find_new_stories(lines, remote_stories_by_id)
    local_task_ids = lines
      .select {|line| TodoParser.is_task?(line) }
      .map {|task| task["local"]["id"]}
      .uniq.compact
    new_ids = remote_stories_by_id.keys - local_task_ids
    remote_stories_by_id
      .select {|id, _stories| new_ids.include?(id)}
      .values
      .map {|stories| { "remote" => stories[0] }}
  end

  def add_local_changesets(lines, scale)
    lines.map do |line|
      if TodoParser.is_task?(line)
        TodoReconciler.add_local_changeset(line, scale)
      else
        line
      end
    end
  end

  def apply_local_changesets(lines)
    lines.map do |line|
      if TodoParser.is_task?(line)
        TodoReconciler.apply_local_changeset(line)
      else
        line
      end
    end
  end

  def add_remote_changesets(lines, scale)
    lines.map do |line|
      if TodoParser.is_task?(line)
        PivotalReconciler.add_remote_changeset(line, scale)
      else
        line
      end
    end
  end
end
