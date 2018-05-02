module TodoParser
  module_function

  def parse_one(line, owners=[])
    current_state, rest_of_line = get_current_state(line)
    estimate     , rest_of_line = get_estimate(rest_of_line)
    story_type   , rest_of_line = get_story_type(rest_of_line)
    owner_ids    , rest_of_line = get_owner_ids(rest_of_line, owners)
    labels       , rest_of_line = get_labels(rest_of_line)
    id           , rest_of_line = get_id(rest_of_line)
    name                        = get_name(rest_of_line)
    { "current_state" => current_state,
      "estimate" => estimate,
      "story_type" => story_type,
      "owner_ids" => owner_ids,
      "labels" => labels,
      "id" => id,
      "name" => name,
    }
  end

  def get_current_state(rest_of_line)
    r = /^(-|\+|\*)/
    [ (rest_of_line.match(r) || [])[1],
      rest_of_line.gsub(r, "").strip]
  end

  def get_estimate(rest_of_line)
    r = /^(\(\d\))/
    match = rest_of_line.match(r)
    estimate = match ? match[1].match(/\d/)[0] : nil
    [ estimate,
      rest_of_line.gsub(r, "").strip ]
  end

  def get_story_type(rest_of_line)
    r = /^\((chore|bug|release)\)/
    [ (rest_of_line.match(r) || [])[1] || "feature",
      rest_of_line.gsub(r, "").strip ]
  end

  def get_owner_ids(rest_of_line, owners)
    r = /@(\w+)/
    owner_initials = rest_of_line.scan(r).flatten
    owner_ids = owner_initials.map {|initials| find_owner_id_by_initials(initials, owners)}
    [ owner_ids.uniq.compact,
      rest_of_line.gsub(r, "").strip ]
  end

  def find_owner_id_by_initials(initials, owners)
    owner = owners.find do |o|
      o["person"]["initials"].downcase == initials.downcase
    end
    owner ? owner["person"]["id"] : nil
  end

  def get_labels(rest_of_line)
    r = /#([\w\s]+)/
    [ rest_of_line.scan(r).flatten.map {|l| l.strip}.uniq.compact,
      rest_of_line.gsub(r, "").strip ]
  end

  def get_id(rest_of_line)
    r = /:ID:(\d+)$/
    [ (rest_of_line.match(r) || [])[1],
      rest_of_line.gsub(r, "").strip ]
  end
  
  def get_name(rest_of_line)
    rest_of_line.strip
  end
end