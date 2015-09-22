require 'test_helper'

describe Site do
  let(:user) { User.create(twitter_uid: 123, token: 'abc', secret: 'foo') }
  subject { user.add_site(name: 'Test', slug: 'test', latest_term_csv: 'test/fixtures/test.csv') }

  describe '#unique_people' do
    it "doesn't return duplicate people or people with an end_date from the CSV" do
      assert_equal 3, subject.unique_people.size
    end
  end

  describe '#grouped_areas' do
    it 'returns the area groupings for the site' do
      assert_equal 3, subject.grouped_areas['Place'].size
      assert_equal 'Bob Tester', subject.grouped_areas['Place'][0][:name]
    end
  end

  describe '#submission_url' do
    it 'returns SUBMISSION_URL from the environment' do
      assert_equal ENV['SUBMISSION_URL'], subject.submission_url
    end
  end

  describe '#url' do
    it 'creates a url from the github repo' do
      subject.github = 'foo/bar'
      assert_equal 'https://foo.github.io/bar', subject.url
      subject.github = 'baz/qux'
      assert_equal 'https://baz.github.io/qux', subject.url
    end
  end

  describe '#twitter_client' do
    it 'is an instance of Twitter::REST::Client' do
      assert subject.twitter_client.instance_of?(Twitter::REST::Client)
    end
  end

  describe '#create_or_update_areas' do
    it 'creates or updates the areas for the site' do
      Sinatra::Application.enable :use_twitter
      area = Minitest::Mock.new
      area.expect :twitter_list, 42
      twitter_client = Minitest::Mock.new
      twitter_client.expect(:add_list_members, true, [42, ["bobtesterfake123", "bobfoo", "bobbar"]])
      subject.stub :twitter_client, twitter_client do
        Area.stub :find_or_create, area do
          subject.create_or_update_areas
        end
      end
      twitter_client.verify
    end
  end
end
