require 'test_helper'

class AppTest < Minitest::Spec
  before :each do
    @user_id = app.database[:users].insert(
      twitter_uid: '1',
      token: 'twitter-token',
      secret: 'twitter-secret'
    )
    app.set :countries, '/test-country' => {
      name: 'Test Country',
      url: '/test-country',
      latest_term_csv: '/test-country.csv'
    }
  end

  it 'has a homepage' do
    get '/'
    assert last_response.ok?
  end

  describe 'creating countries' do
    it 'lets you choose a country' do
      post '/countries', { country: '/test-country' }, 'rack.session' => { user_id: @user_id }
      assert last_response.redirect?
      assert_equal 'http://example.org/', last_response.location
    end
  end

  describe 'posting updates' do
    it 'creates a new submission entry' do
      country_id = app.database[:countries].insert(app.countries['/test-country'].dup.merge(user_id: @user_id))
      post '/submissions', submission: { country_id: country_id, person_id: 42, twitter: 'barackobama' }
      assert last_response.redirect?
      assert_equal 'http://example.org/submissions/1', last_response.location
      get last_response.location
      assert last_response.ok?
      assert last_response.body.include?('Your update has been submitted for approval')
      assert last_response.body.include?('barackobama')
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
