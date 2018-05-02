class Todo::Story
  attr_accessor :id, :status, :name, :owners, :labels, :url, :points

  STATUS_NAME_BY_SYMBOL = { "-" => "unstarted", "+" => "started", "*" => "finished" }
  LINK_TEXT = "Link"

  def initialize(line)
    [@status, rest_of_line] = get_status(line)
    [@points, rest_of_line] = get_points(rest_of_line)
    [@type,   rest_of_line] = get_type(rest_of_line)
    [@owners, rest_of_line] = get_owners(rest_of_line)
    [@labels, rest_of_line] = get_labels(rest_of_line)
    [@url,    rest_of_line] = get_url(rest_of_line)
    @name                   = get_name(rest_of_line)
    @id                     = get_id
  end

  def to_json
    {
      status: STATUS_NAME_BY_SYMBOL[@status],
      name: @name,
      owners: @owners,
      labels: @labels,
    }.to_json
  end

  private

  def get_status(rest_of_line)
    r = /^(-|\+|\*)/
    [ rest_of_line.match(r)[1],
      rest_of_line.gsub(r, "").strip]
  end

  def get_points(rest_of_line)
    r = /^(\(\d\))/
    [ rest_of_line.match(r)[1],
      rest_of_line.gsub(r, "").strip ]
  end

  def get_type(rest_of_line)
    r = /^\((chore|bug|release)\)/
    [ rest_of_line.match(r)[1],
      rest_of_line.gsub(r, "").strip ]
  end

  def get_owners(rest_of_line)
    r = /@\w+/
    [ rest_of_line.scan(r),
      rest_of_line.gsub(r, "").strip ]
  end

  def get_labels(rest_of_line)
    r = /#\w+/
    [ rest_of_line.scan(r),
      rest_of_line.gsub(r, "").strip ]
  end

  def get_url(rest_of_line)
    r = /\[#{LINK_TEXT}\]\((.*)\)$/
    [ rest_of_line.match(r)[1],
      rest_of_line.gsub(r, "").strip ]
  end

  def get_id
    @url.split('/')[-1]
  end
  
  def get_name(rest_of_line)
    rest_of_line.strip
  end
end