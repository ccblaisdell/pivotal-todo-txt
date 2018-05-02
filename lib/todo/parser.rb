module TodoParser
  def parse_one(line, owners=[])
    current_state, rest_of_line = get_current_state(line)
    estimate     , rest_of_line = get_estimate(rest_of_line)
    story_type   , rest_of_line = get_story_type(rest_of_line)
    owners       , rest_of_line = get_owners(rest_of_line, owners)
    labels       , rest_of_line = get_labels(rest_of_line)
    id           , rest_of_line = get_id(rest_of_line)
    name                        = get_name(rest_of_line)
    { "current_state" => current_state,
      "estimate" => estimate,
      "story_type" => story_type,
      "owners" => owners,
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

  def get_owners(rest_of_line, owners)
    r = /@(\w+)/
    [ rest_of_line.scan(r).flatten,
      rest_of_line.gsub(r, "").strip ]
  end

  def get_labels(rest_of_line)
    r = /#([\w\s]+)/
    [ rest_of_line.scan(r).flatten.map {|l| l.strip},
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