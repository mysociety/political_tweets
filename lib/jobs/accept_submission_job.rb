require 'base64'
require 'date'

class AcceptSubmissionJob
  @queue = :default

  def self.perform(submission_id)
    submission = Submission[submission_id]
    country_name = submission.country.name.gsub(' ', '_')
    org = SeePoliticiansTweet::App.github_organization
    github_repository = "#{org}/everypolitician-data"
    csv_path = "data/#{country_name}/seepoliticianstweet.csv"
    begin
      existing_csv = client.contents(
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
        repo = client.repository(github_repository)
        `git clone --depth=1 --quiet #{clone_url(repo)} .`
        branch_name = "#{country_name.downcase}-#{DateTime.now.strftime('%Y%m%d%H%M%S')}"
        `git checkout -b #{branch_name}`
        File.open(csv_path, 'w') do |f|
          f.puts csv
        end
        `git add .`
        author = "#{client.login} <#{client.emails.first[:email]}>"
        message = "Automated commit for #{submission.country.name}"
        `git commit --author="#{author}" --message="#{message}"`
        `git push --quiet origin #{branch_name}`

        pull_request = client.create_pull_request(
          # TODO: Change chrismytton to everypolitician once it's working correctly
          'chrismytton/everypolitician-data',
          'master',
          "#{org}:#{branch_name}",
          "New Twitter details for #{submission.country.name}"
        )
      end
    end
  end

  def self.clone_url(repo)
    repo_clone_url = URI.parse(repo.clone_url)
    repo_clone_url.user = client.login
    repo_clone_url.password = client.access_token
    repo_clone_url
  end

  def self.client
    @client ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end
end
