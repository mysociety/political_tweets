module SeePoliticiansTweet
  module Models
    class Site < Sequel::Model
      many_to_one :user
      one_to_many :submissions

      def active?
        !github.nil?
      end
    end
  end
end
