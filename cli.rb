require 'slop'
require './sync'

# eventual usage
# ruby pivotal-todo-txt --watch --file ~/dev/icmib/todo.md

opts = Slop.parse do |o|
  o.string '-f', '--file', 'path to file'
  o.bool '-w', '--watch', 'enable watch mode'
end

Sync.new(opts)

# TODOs!
# remember structure of last sync
# work out changeset for local file
# work out changeset for remote
# apply changesets in bulk
# remember output

# create tmLanguage
# create gem

# publish both for easier consumption

# lines should be [ string, string, ID, ID, string, ID ] where ID maps to the tasks hash
# tasks hash is keyed by task ID, Maybe we also have a separate structure for ones without ID?
# the tasks hash will hold last saved state, new local state and new remote state.
# something like { [id]: { previous: {...}, local: {...}, remote: {...}, localChangeset: {...}, remoteChangeset: {...} } }
# We will use them together to reconcile and create changesets
