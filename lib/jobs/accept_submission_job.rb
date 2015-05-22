require 'base64'
require 'date'
require 'github'

class AcceptSubmissionJob
  include Github

  @queue = :default

  def self.perform(submission_id)
    submission = Submission[submission_id]
    new(submission).accept_submission
  end

  attr_reader :submission

  def initialize(submission)
    @submission = submission
  end

  def accept_submission
    org = SeePoliticiansTweet::App.github_organization
    github_repository = "#{org}/everypolitician-data"
    country_name = submission.country.name.gsub(' ', '_')
    csv_path = "data/#{country_name}/seepoliticianstweet.csv"
    begin
      existing_csv = github_client.contents(
        github_repository,
        path: csv_path
      )
      csv_text = Base64.decode64(existing_csv[:content])
      csv = CSV.parse(csv_text, headers: true)
    rescue Octokit::NotFound
      # No existing CSV
      csv = CSV::Table.new([])
    end
    csv << CSV::Row.new([:id, :twitter], [submission.person_id, submission.twitter])
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        repo = github_client.repository(github_repository)
        `git clone --depth=1 --quiet #{clone_url(repo)} .`
        branch_name = "#{country_name.downcase}-#{DateTime.now.strftime('%Y%m%d%H%M%S')}"
        `git checkout -q -b #{branch_name}`
        File.open(csv_path, 'w') { |f| f.puts(csv) }
        `git add .`
        git_config = "-c user.name='#{github_client.login}' -c user.email='#{github_client.emails.first[:email]}'"
        message = "Automated commit for #{submission.country.name}"
        `git #{git_config} commit --message="#{message}"`
        `git push --quiet origin #{branch_name}`

        pull_request = github_client.create_pull_request(
          # TODO: Change chrismytton to everypolitician once it's working correctly
          'chrismytton/everypolitician-data',
          'master',
          "#{org}:#{branch_name}",
          "New Twitter details for #{submission.country.name}"
        )
      end
    end
  end
end
