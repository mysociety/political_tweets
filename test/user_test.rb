require 'test_helper'

describe User do
  it 'has a twitter_client' do
    user = User.new
    assert user.twitter_client.instance_of?(Twitter::REST::Client)
  end
end
