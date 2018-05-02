require 'json'
require 'rest-client'

module PivotalApi
  module_function
  
  BASE_PATH = "https://www.pivotaltracker.com/services/v5"
  FIELDS = %w(id current_state estimate labels name owner_ids story_type url).join(',')

  def fetch_owners
    response = get("/memberships")
    JSON.parse(response.body)
  end

  def fetch_labels
    response = get("/labels")
    JSON.parse(response.body)
  end

  def fetch_epics
    response = get("/epics")
    JSON.parse(response.body)
  end

  def fetch_my_stories
    filters = "mywork:#{ENV['MY_PIVOTAL_INITIALS']}"
    response = get("/stories?fields=#{URI.encode FIELDS}&filter=#{URI.encode filters}")
    JSON.parse(response.body)
  end

  def fetch_support_stories
    filters = "label:support,urgent"
    response = get("/stories?fields=#{URI.encode FIELDS}&filter=#{URI.encode filters}")
    JSON.parse(response.body)
  end

  def create_story(story)
    body = story.compact.reject {|k,v| v.is_a?(Array) && v.empty?}
    response = post("/stories?fields=#{URI.encode FIELDS}", body)
    JSON.parse(response.body)
  end

  def update_story(story)
    body = story.compact.reject {|k,v| v.is_a?(Array) && v.empty?}
    response = put("/stories/#{story["id"]}", body)
    JSON.parse(response.body)
  end

  def get(path)
    RestClient.get(
      "#{BASE_PATH}/projects/#{ENV["PIVOTAL_PROJECT_ID"]}#{path}",
      "X-TrackerToken" => ENV["PIVOTAL_API_KEY"])
  end

  def post(path, payload={})
    begin
      RestClient.post(
        "#{BASE_PATH}/projects/#{ENV["PIVOTAL_PROJECT_ID"]}#{path}",
        payload,
        { "X-TrackerToken" => ENV["PIVOTAL_API_KEY"] }
      )
    rescue RestClient::ExceptionWithResponse => e
      e.response
    end
  end

  def put(path, payload={})
    begin
      RestClient.put(
        "#{BASE_PATH}/projects/#{ENV["PIVOTAL_PROJECT_ID"]}#{path}",
        payload,
        { "X-TrackerToken" => ENV["PIVOTAL_API_KEY"] }
      )
    rescue RestClient::ExceptionWithResponse => e
      e.response
    end
  end
end
