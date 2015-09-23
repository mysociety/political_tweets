require 'test_helper'

describe JekyllSiteGeneratorJob do
  let(:user) { User.create(twitter_uid: 123, token: 'abc', secret: 'foo') }
  let(:site) { user.add_site(name: 'Test', slug: 'test', latest_term_csv: 'test/fixtures/test.csv') }

  it 'generates the requested site' do
    skip('Need to add tests for JekyllSiteGeneratorJob')
    # site_generator = JekyllSiteGeneratorJob.new
    # site_generator.perform(site.id)
  end
end
