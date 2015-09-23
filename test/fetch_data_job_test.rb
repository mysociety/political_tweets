require 'test_helper'

describe FetchDataJob do
  it 'updates areas and the all list' do
    fake_site = Minitest::Mock.new
    fake_site.expect :create_or_update_areas, true
    fake_site.expect :create_or_update_all_list, true
    fake_site.expect :id, 42
    Site.stub :[], fake_site do
      JekyllSiteGeneratorJob.stub :perform_async, true do
        fetch_data_job = FetchDataJob.new
        fetch_data_job.perform(42)
        fake_site.verify
      end
    end
  end
end
