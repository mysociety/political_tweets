require 'test_helper'

class AppTest < Minitest::Spec
  include Rack::Test::Methods

  def app
    SeePoliticiansTweet::App
  end

  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end

  it "has a homepage" do
    get '/'
    assert last_response.ok?
  end

  describe "creating countries" do
    before :each do
      @user_id = app.database[:users].insert(
        twitter_uid: '123',
        token: 'TK',
        secret: 'SK'
      )
    end

    it "lets you choose a country" do
      post '/countries', {country: '/wales'}, {'rack.session' => {user_id: @user_id}}
      assert last_response.redirect?
      assert_equal 'http://example.org/countries/1', last_response.location
    end
  end
end
