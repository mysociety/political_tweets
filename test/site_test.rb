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
end
