require 'ocd_division_id'

# Background job to create Twitter lists from site data
class FetchDataJob
  include Sidekiq::Worker

  attr_reader :site

  def perform(site_id)
    @site = Site[site_id]

    csv = site.csv.map(&:to_hash).uniq { |person| person['id'] }
    csv = csv.reject { |row| row['end_date'] }

    areas = parse_areas_from_csv(csv)
    areas = create_lists_for_areas(areas)
    create_all_list(site.csv)

    # Generate the static site
    JekyllSiteGeneratorJob.perform_async(site.id, site.twitter_client.user.screen_name, areas)
  end

  def parse_areas_from_csv(csv)
    raise OcdDivisionId::InvalidDivisionId unless site.name == 'Australia (House of Representatives)'
    australia_csv = CSV.parse(open('country-au.csv').read, headers: true)
    australia = {}
    australia_csv.each do |row|
      australia[row['id']] = row['name']
    end
    area_ids = csv.map { |row| OcdDivisionId.new(row['area_id']) }
    id_set = OcdDivsionIdSet.new(*area_ids)
    # grouping = id_set.common_type
    grouping = :state
    areas = id_set.map { |id| australia[id.id_for(grouping)] }.compact.uniq
    areas = areas.map { |a| { name: a } }
    csv.each do |row|
      area = areas.find { |a| a[:name] == australia[OcdDivisionId.new(row['area_id']).id_for(grouping)] }
      next unless area
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
    all_lists = site.twitter_client.lists
    areas.map do |area|
      # Twitter list names must be 25 chars or less
      name = area[:name]
      if name.length > 25
        name = name[0...25]
      end

      list = all_lists.find { |l| l.name == name }

      unless list
        list = site.twitter_client.create_list(name)
      end

      area[:list_id] = list.id
      area[:list_slug] = list.slug

      list_members = area[:politicians].map { |p| p[:twitter] }.compact
      begin
        site.twitter_client.add_list_members(list, list_members)
      rescue Twitter::Error::Forbidden, Twitter::Error::NotFound
        list_members.each do |member|
          begin
            site.twitter_client.add_list_member(list, member)
          rescue Twitter::Error::Forbidden, Twitter::Error::NotFound
            next
          end
        end
      end

      area
    end
  end

  def create_all_list(csv)
    # Create a list with all members in
    all_list = site.twitter_client.lists.find { |list| list.name == 'All' }
    unless all_list
      all_list = site.twitter_client.create_list('All')
    end
    all_twitter_handles = csv.map do|row|
      row['twitter'] if row['twitter']
    end.compact
    site.twitter_client.add_list_members(all_list, all_twitter_handles)
  end
end
