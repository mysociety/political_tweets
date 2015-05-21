module SeePoliticiansTweet
  module Models
    class Submission < Sequel::Model
      many_to_one :country
    end
  end
end
