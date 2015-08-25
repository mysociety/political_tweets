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

      def csv_url
        @csv_url ||= 'https://raw.githubusercontent.com/' \
          "everypolitician/everypolitician-data/master/#{latest_term_csv}"
      end

      def csv_data
        @csv_data ||= open(csv_url).read
      end

      def url
        org, repo = github.split('/')
        "https://#{org}.github.io/#{repo}"
      end
    end
  end
end
