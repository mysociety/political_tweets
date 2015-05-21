module SeePoliticiansTweet
  module Models
    class User < Sequel::Model
      one_to_many :countries
    end
  end
end
