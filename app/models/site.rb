require 'csv'
require 'ocd_division_id'
require 'github'

module SeePoliticiansTweet
  module Models
    class Site < Sequel::Model
      many_to_one :user
      one_to_many :submissions
      one_to_many :areas

      dataset_module do
        def active
          exclude(url: nil)
        end
      end

      def active?
        !url.nil?
      end

      def csv
        @csv ||= CSV.parse(csv_data, headers: true, header_converters: :symbol)
      end

      def csv_data
        @csv_data ||= open(latest_term_csv).read
      end

      def unique_people
        @unique_people ||= csv.map(&:to_hash)
          .uniq { |person| person[:id] }
          .reject { |row| row[:end_date] }
      end

      def twitter_client
        user.twitter_client
      end

      def submission_url
        ENV['SUBMISSION_URL']
      end

      def slug
        [country_slug, legislature_slug].join('_')
      end

      def github_repository
        [github_organization, slug].join('/')
      end

      def local?
        url.start_with?('http://127.0.0.1:4000')
      end

      def grouped_areas
        @grouped_areas ||= unique_people.group_by { |person| person[:area].strip }
      end

      def countries_with_twitter_handles
        @countries_with_twitter_handles ||=
          begin
            countries = {}
            everypolitican_data = File.expand_path('/everypolitician-data', __FILE__)
            Sinatra::Application.countries.each do |country|
              country[:legislatures].each do |l|
                lp = l[:legislative_periods].first
                csv_url = 'https://raw.githubusercontent.com/everypolitician/' \
                  "everypolitician-data/master/#{lp[:csv]}"
                csv_text = open(csv_url).read
                csv_data = CSV.parse(csv_text, headers: true, header_converters: :symbol)
                unique_people = csv_data.map(&:to_hash)
                  .uniq { |person| person[:id] }
                  .reject { |row| row[:end_date] }
                if unique_people.map { |p| p[:twitter] }.compact.count >= 2
                  countries[country[:name]] = unique_people
                end
              end
            end
            countries
          end
      end

      def create_or_update_areas
        countries_with_twitter_handles.each do |name, politicians|
          area = Area.find_or_create(site_id: id, name: name)

          next unless Sinatra::Application.use_twitter?

          list_members = politicians.map { |p| p[:twitter] }.compact
          begin
            twitter_client.add_list_members(area.twitter_list, list_members)
          rescue Twitter::Error::Forbidden, Twitter::Error::NotFound
            list_members.each do |member|
              begin
                twitter_client.add_list_member(area.twitter_list, member)
              rescue Twitter::Error::Forbidden, Twitter::Error::NotFound
                next
              end
            end
          end
        end
      end

      # Create a list with all members in
      def create_or_update_all_list
        return unless Sinatra::Application.use_twitter?
        all_twitter_handles = unique_people.map { |row| row[:twitter] }.compact
        twitter_client.add_list_members(all_list, all_twitter_handles)
      end

      def all_list
        all_list = twitter_client.list(twitter_all_list_id)
      rescue Twitter::Error::NotFound, Twitter::Error::BadRequest
        all_list = twitter_client.create_list('All')
        self.twitter_all_list_id = all_list.id
        self.twitter_all_list_slug = all_list.slug
        save
        all_list
      end

      def with_tmp_dir(&block)
        Dir.mktmpdir do |tmp_dir|
          Dir.chdir(tmp_dir, &block)
        end
      end

      def clone_url(repo)
        repo_clone_url = URI.parse(repo.clone_url)
        repo_clone_url.user = GitHub.login
        repo_clone_url.password = GitHub.access_token
        repo_clone_url
      end

      def with_git_repo
        with_tmp_dir do |dir|
          create_or_update_repo
          yield(dir)
          commit_and_push
        end
      end

      def create_or_update_repo
        if GitHub.repository?(github_repository)
          repo = GitHub.repository(github_repository)
          `git clone --quiet #{clone_url(repo)} .`
        else
          # Repository doesn't exist yet
          repo = GitHub.create_repository(
            github_repository,
            organization: org,
            homepage: url
          )
          `git init`
          `git symbolic-ref HEAD refs/heads/gh-pages`
          `git remote add origin #{clone_url(repo)}`
        end
      end

      def commit_and_push
        `git add .`
        git_config = "-c user.name='#{GitHub.login}' " \
          "-c user.email='#{GitHub.emails.first[:email]}'"
        message = 'Automated commit'
        `git #{git_config} commit --message="#{message}"`
        `git push --quiet origin gh-pages`
      end
    end
  end
end
