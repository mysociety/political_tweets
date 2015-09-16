module SeePoliticiansTweet
  module Models
    class User < Sequel::Model
      one_to_many :sites

      def twitter_client
        @twitter_client ||= Twitter::REST::Client.new do |config|
          config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
          config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
          config.access_token        = token
          config.access_token_secret = secret
        end
      end
    end
  end
end
