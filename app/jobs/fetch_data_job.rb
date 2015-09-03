require 'ocd_division_id'

# Background job to create Twitter lists from site data
class FetchDataJob
  include Sidekiq::Worker

  attr_reader :site

  def perform(site_id)
    @site = Site[site_id]

    areas = parse_areas_from_csv(site.csv)
    areas = create_lists_for_areas(areas)
    create_all_list(site.csv)

    # Generate the static site
    JekyllSiteGeneratorJob.perform_async(site.id, client.user.screen_name, areas)
  end

  def client
    @client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = site.user.token
      config.access_token_secret = site.user.secret
    end
  end

  def parse_areas_from_csv(csv)
    area_ids = csv.map { |row| OcdDivisionId.new(row['area_id']) }
    id_set = OcdDivsionIdSet.new(*area_ids)
    grouping = id_set.common_type
    areas = id_set.map { |id| { name: id.id_for(grouping) } }
    csv.each do |row|
      area = areas.find { |a| a[:name] == OcdDivisionId.new(row['area_id']).id_for(grouping) }
      area[:politicians] ||= []
      area[:politicians] << {
        id: row['id'],
        name: row['name'],
        twitter: row['twitter']
      }
    end
    areas
  rescue OcdDivisionId::InvalidDivisionId
    areas = csv.map { |r| r['area'].strip }.compact.uniq
    areas = areas.map { |a| { name: a } }
    csv.each do |row|
      area = areas.find { |a| a[:name] == row['area'].strip }
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

      list = all_lists.find { |l| l.name == name }

      unless list
        list = client.create_list(name)
      end

      area[:list_id] = list.id
      area[:list_slug] = list.slug

      list_members = area[:politicians].map { |p| p[:twitter] }.compact
      list_members.each do |member|
        begin
          client.add_list_member(list, member)
        rescue Twitter::Error::Forbidden, Twitter::Error::NotFound
          next
        end
      end

      area
    end
  end

  def create_all_list(csv)
    # Create a list with all members in
    all_list = client.lists.find { |list| list.name == 'All' }
    unless all_list
      all_list = client.create_list('All')
    end
    all_twitter_handles = csv.map do|row|
      row['twitter'] if row['twitter']
    end.compact
    client.add_list_members(all_list, all_twitter_handles)
  end
end
