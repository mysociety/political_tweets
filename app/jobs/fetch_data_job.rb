# Background job to create Twitter lists from site data
class FetchDataJob
  include Sidekiq::Worker

  def perform(site_id)
    site = Site[site_id]

    site.create_or_update_areas
    site.create_or_update_all_list

    # Generate the static site
    JekyllSiteGeneratorJob.perform_async(site.id)
  end
end
