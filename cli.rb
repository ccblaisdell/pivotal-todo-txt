require 'slop'
require './sync'

# eventual usage
# ruby pivotal-todo-txt --watch --file ~/dev/icmib/todo.md

opts = Slop.parse do |o|
  o.string '-f', '--file', 'path to file'
  o.bool '-w', '--watch', 'enable watch mode'
end

Sync.new(opts)
