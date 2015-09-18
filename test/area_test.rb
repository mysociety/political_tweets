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
end
