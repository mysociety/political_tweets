require 'csv'

module SeePoliticiansTweet
  module Models
    class Site < Sequel::Model
      many_to_one :user
      one_to_many :submissions

      def active?
        !github.nil?
      end

      def csv
        @csv ||= CSV.parse(csv_data, headers: true)
      end

      def csv_data
        @csv_data ||= open(latest_term_csv).read
      end

      def url
        org, repo = github.split('/')
        "https://#{org}.github.io/#{repo}"
      end

      def twitter_client
        user.twitter_client
      end

      def submission_url
        ENV['SUBMISSION_URL']
      end
    end
  end
end
