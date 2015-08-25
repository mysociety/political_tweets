require 'test_helper'

class AppTest < Minitest::Spec
  before :each do
    @user_id = app.database[:users].insert(
      twitter_uid: '1',
      token: 'twitter-token',
      secret: 'twitter-secret'
    )
    app.set :countries, [
      {
        name: 'Test Country',
        slug: 'Test_Country',
        legislatures: [
          {
            slug: 'Example',
            legislative_periods: [
              {
                csv: 'foo/bar.csv'
              }
            ]
          }
        ]
      }
    ]
  end

  it 'has a homepage' do
    get '/'
    assert last_response.ok?
  end

  describe 'creating countries' do
    it 'lets you choose a country' do
      post '/sites', { country_legislature: 'Test_Country:Example' }, 'rack.session' => { user_id: @user_id }
      assert last_response.redirect?
      assert_equal 'http://example.org/', last_response.location
    end
  end

  describe Site do
    it 'has an active? method' do
      site = Site.new
      assert !site.active?
      site.github = 'foo/bar'
      assert site.active?
    end
  end
end
