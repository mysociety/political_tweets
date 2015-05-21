require 'csv'

# Resque job to create Twitter lists from country data
class FetchDataJob
  @queue = :default

  def self.perform(country_id)
    country = Country[country_id]
    new(country).fetch
  end

  attr_reader :country
  attr_reader :csv

  def initialize(country)
    @country = country
    @csv = get_csv_for_country(country)
  end

  def fetch
    areas = parse_areas_from_csv(csv)
    areas = create_lists_for_areas(areas)
    create_all_list

    # Generate the static site
    Resque.enqueue(JekyllSiteGeneratorJob, country.id, client.user.screen_name, areas)
  end

  def client
    @client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = country.user.token
      config.access_token_secret = country.user.secret
    end
  end

  def get_csv_for_country(country)
    latest_term_csv = country.latest_term_csv
    term_csv = open('http://data.everypolitician.org' + latest_term_csv).read
    CSV.parse(term_csv, headers: true)
  end

  def parse_areas_from_csv(csv)
    areas = csv.map { |r| r['area'] }.compact.uniq
    areas = areas.map { |a| {name: a} }
    csv.each do |row|
      area = areas.find { |a| a[:name] == row['area'] }
      area[:politicians] ||= []
      area[:politicians] << {
        id: row['id'],
        name: row['name'],
        twitter: row['twitter']
      }
    end
    areas
  end

  def create_lists_for_areas(areas)
    all_lists = client.lists
    areas.map do |area|
      # Twitter list names must be 25 chars or less
      name = area[:name]
      if name.length > 25
        name = name[0...25]
      end

      list = all_lists.find { |list| list.name == name }

      if !list
        list = client.create_list(name)
      end

      area[:list_id] = list.id
      area[:list_slug] = list.slug

      list_members = area[:politicians].map { |p| p[:twitter] }.compact
      client.add_list_members(list, list_members)

      area
    end
  end

  def create_all_list
    # Create a list with all members in
    all_list = client.lists.find { |list| list.name == 'All' }
    if !all_list
      all_list = client.create_list('All')
    end
    all_twitter_handles = csv.map do|row|
      row['twitter'] if row['twitter']
    end.compact
    client.add_list_members(all_list, all_twitter_handles)
  end
end
