module PivotalSerializer
  def serialize_all(stories, owners)
    stories.map {|story| serialize_one(story, owners)}
  end

  def serialize_one(story, owners)
    output = []
    output << put_state(story)
    output << put_estimate(story)
    output << put_story_type(story)
    output << put_name(story)
    output << put_owners(story, owners)
    output << put_labels(story)
    output << put_id(story)
    output.flatten.compact.join(" ")
  end

  def put_state(story)
    case story["current_state"]
    when "unstarted"
      "-"
    when "started"
      "+"
    when "finished"
    when "delivered"
    when "accepted"
      "*"
    else
      "-"
    end
  end

  def put_estimate(story)
    "(#{story["estimate"]})" if story["estimate"]
  end

  def put_story_type(story)
    "(#{story["story_type"]})" unless story["story_type"] == "feature"
  end

  def put_name(story)
    story["name"].strip
  end

  def put_owners(story, owners)
    story["owner_ids"].to_a
      .map {|id| owners.to_a.find {|owner| owner["person"]["id"] == id}}
      .map {|owner| "@#{owner["person"]["initials"]}"}
  end

  def put_labels(story)
    story["labels"].to_a.map {|label| "##{label}"}
  end

  def put_id(story)
    ":ID:#{story["id"]}"
  end
end