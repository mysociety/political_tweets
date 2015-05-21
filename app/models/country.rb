module SeePoliticiansTweet
  module Models
    class Country < Sequel::Model
      many_to_one :user
      one_to_many :submissions
    end
  end
end
