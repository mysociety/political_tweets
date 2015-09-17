module SeePoliticiansTweet
  module Models
    class Area < Sequel::Model
      many_to_one :site

      # Twitter list names must be 25 chars or less
      def twitter_list_name
        name[0...25]
      end

      def twitter_list
        twitter_client.list(area.twitter_list_id)
      rescue Twitter::Error::NotFound, Twitter::Error::BadRequest
        list = twitter_client.create_list(area.twitter_list_name)
        self.twitter_list_id = list.id
        self.twitter_list_slug = list.slug
        save
        list
      end
    end
  end
end
