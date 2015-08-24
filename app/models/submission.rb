module SeePoliticiansTweet
  module Models
    class Submission < Sequel::Model
      many_to_one :site
    end
  end
end
