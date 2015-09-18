module SeePoliticiansTweet
  module Models
    class Area < Sequel::Model
      many_to_one :site

      # Twitter list names must be 25 chars or less
      def twitter_list_name
        name[0...25]
      end

      def twitter_list
        if !twitter_list_id
          list = site.twitter_client.create_list(twitter_list_name)
          self.twitter_list_id = list.id
          self.twitter_list_slug = list.slug
          save
        end
        twitter_list_id
      end
    end
  end
end
