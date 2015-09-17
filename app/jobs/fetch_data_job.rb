require 'ocd_division_id'

# Background job to create Twitter lists from site data
class FetchDataJob
  include Sidekiq::Worker

  attr_reader :site

  def perform(site_id)
    @site = Site[site_id]

    site.create_or_update_areas
    site.create_or_update_all_list

    # Generate the static site
    JekyllSiteGeneratorJob.perform_async(site.id)
  end
end
