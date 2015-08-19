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
      post '/countries', { country: 'Test_Country' }, 'rack.session' => { user_id: @user_id }
      assert last_response.redirect?
      assert_equal 'http://example.org/', last_response.location
    end
  end

  describe Country do
    it 'has an active? method' do
      country = Country.new
      assert !country.active?
      country.github = 'foo/bar'
      assert country.active?
    end
  end
end
