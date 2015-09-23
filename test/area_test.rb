require 'test_helper'

describe Area do
  it 'has a 25 char Twitter list name' do
    area = Area.new(name: 'Carmarthen West and Pembrokeshire South')
    assert_equal 'Carmarthen West and Pembr', area.twitter_list_name
  end

  it 'has a slug' do
    area = Area.new(name: 'Jõgeva- ja Tartumaa')
    assert_equal 'jogeva-ja-tartumaa', area.slug
  end

  describe '#twitter_list' do
    it 'returns the twitter list id if there is one' do
      area = Area.new(name: 'Townville', twitter_list_id: '123456')
      assert_equal 123456, area.twitter_list
    end

    it "creates the list and updates the id if there isn't one already" do
      list = Minitest::Mock.new
      list.expect :id, '42'
      list.expect :slug, 'forty-two'
      twitter_client = Minitest::Mock.new
      twitter_client.expect :create_list, list, ['Townville']
      site = Minitest::Mock.new
      site.expect :twitter_client, twitter_client
      area = Area.new(name: 'Townville')
      area.stub :site, site do
        area.stub :save, true do
          area.twitter_list
          assert_equal 42, area.twitter_list_id
          assert_equal 'forty-two', area.twitter_list_slug
        end
      end
    end
  end
end
