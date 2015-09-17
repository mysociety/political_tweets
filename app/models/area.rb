module SeePoliticiansTweet
  module Models
    class Area < Sequel::Model
      many_to_one :site

      # Twitter list names must be 25 chars or less
      def twitter_list_name
        name[0...25]
      end
    end
  end
end
