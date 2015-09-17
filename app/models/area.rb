module SeePoliticiansTweet
  module Models
    class Area < Sequel::Model
      many_to_one :site
    end
  end
end
