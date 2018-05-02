module PivotalParser
  def parse_all(stories)
    stories
      .map {|story| parse_one(story)}
      .uniq {|story| story["id"]}
  end

  def parse_one(story)
    {
      "id" => story["id"],
      "current_state" => story["current_state"],
      "estimate" => story["estimate"],
      "labels" => story["labels"].map {|label| label["name"]},
      "name" => story["name"].strip,
      "owner_ids" => story["owner_ids"],
      "story_type" => story["story_type"],
      "url" => story["url"],
    }
  end
end