require 'github'

class JekyllSiteGeneratorJob
  include Sidekiq::Worker
  include Github

  attr_reader :country
  attr_reader :areas

  def perform(country_id, list_owner_screen_name, areas)
    @country = Country[country_id]
    @list_owner_screen_name = list_owner_screen_name
    @areas = areas
    generate
  end

  def templates_dir
    File.expand_path(File.join('..', '..', '..', 'jekyll', 'templates'), __FILE__)
  end

  def repo_dir
    File.expand_path(File.join('..', '..', '..', 'jekyll', 'repo'), __FILE__)
  end

  def generate
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        create_or_update_repo(dir)

        template = Tilt.new(File.join(templates_dir, '_config.yml.erb'))
        config_yml = template.render(
          self,
          country: country,
          list_owner_screen_name: @list_owner_screen_name,
          submission_url: ENV['SUBMISSION_URL']
        )
        File.open(File.join(dir, '_config.yml'), 'w') do |f|
          f.puts(config_yml)
        end
        template = Tilt.new(File.join(templates_dir, 'area.html.erb'))
        areas.each do |area|
          File.open(File.join(dir, '_areas', "#{area['list_slug']}.html"), 'w') do |f|
            f.puts(template.render(self, area))
          end
        end

        `git add .`
        git_config = "-c user.name='#{github_client.login}' -c user.email='#{github_client.emails.first[:email]}'"
        message = "Automated commit for #{country.name}"
        `git #{git_config} commit --message="#{message}"`
        `git push --quiet origin gh-pages`
      end
    end
  end

  def create_or_update_repo(dir)
    org = Sinatra::Application.github_organization
    repo_name = country.url.gsub('/', '')
    if country.github
      github_repository = country.github
    else
      github_repository = "#{org}/#{repo_name}"
      country.github = github_repository
      country.save
    end
    if github_client.repository?(github_repository)
      repo = github_client.repository(github_repository)
      `git clone --quiet #{clone_url(repo)} .`
    else
      # Repository doesn't exist yet
      repo = github_client.create_repository(
        repo_name,
        organization: org,
        homepage: "https://#{org}.github.io/#{repo_name}"
      )
      `git init`
      `git symbolic-ref HEAD refs/heads/gh-pages`
      `git remote add origin #{clone_url(repo)}`
    end

    # Update files in repo
    FileUtils.cp_r(repo_dir + '/.', dir)
  end
end
