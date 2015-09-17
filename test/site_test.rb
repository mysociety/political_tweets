require 'test_helper'

describe Site do
  let(:user) { User.create(twitter_uid: 123, token: 'abc', secret: 'foo') }
  subject { user.add_site(name: 'Test', slug: 'test', latest_term_csv: 'test/fixtures/test.csv') }

  describe '#unique_people' do
    it "doesn't return duplicate people from the CSV" do
      assert_equal 3, subject.unique_people.size
    end
  end

  describe '#areas' do
    it 'returns the area groupings for the site' do
      areas = {
        'Place' => [
          { id: '123', name: 'Bob Tester', twitter: 'bobtesterfake123', area: 'Place', area_id: nil },
          { id: '124', name: 'Bob Foo', twitter: 'bobfoo', area: 'Place', area_id: nil },
          { id: '125', name: 'Bob Bar', twitter: 'bobbar', area: 'Place', area_id: nil }
        ]
      }
      assert_equal areas, subject.areas
    end
  end
end
