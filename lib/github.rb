module Github
  def github_client
    @github_client ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  def clone_url(repo)
    repo_clone_url = URI.parse(repo.clone_url)
    repo_clone_url.user = github_client.login
    repo_clone_url.password = github_client.access_token
    repo_clone_url
  end
end
