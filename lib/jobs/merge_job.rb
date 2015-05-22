class MergeJob
  extend Github

  @queue = :default

  def self.perform(repo, number)
    github_client.merge_pull_request(repo, number)
  end
end
