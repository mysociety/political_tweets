require 'github'
require 'fileutils'

class JekyllSiteGeneratorJob
  include Sidekiq::Worker
  include Github

  attr_reader :site
  attr_reader :areas

  def perform(site_id, list_owner_screen_name, areas)
    @site = Site[site_id]
    @list_owner_screen_name = list_owner_screen_name
    @areas = areas
    generate
  end

  def generate
    with_tmp_dir do |dir|
      create_or_update_repo(dir)

      template = Tilt.new(File.join(templates_dir, '_config.yml.erb'))
      config_yml = template.render(
        self,
        site: site,
        list_owner_screen_name: @list_owner_screen_name,
        submission_url: ENV['SUBMISSION_URL']
      )
      File.open(File.join(dir, '_config.yml'), 'w') do |f|
        f.puts(config_yml)
      end

      FileUtils.rm_rf(File.join(dir, '_areas'))
      FileUtils.mkdir_p(File.join(dir, '_areas'))

      template = Tilt.new(File.join(templates_dir, 'area.html.erb'))
      areas.each do |area|
        File.open(File.join(dir, '_areas', "#{area['list_slug']}.html"), 'w') do |f|
          f.puts(template.render(self, area))
        end
      end

      `git add .`
      git_config = "-c user.name='#{github_client.login}' -c user.email='#{github_client.emails.first[:email]}'"
      message = "Automated commit for #{site.name}"
      `git #{git_config} commit --message="#{message}"`
      `git push --quiet origin gh-pages`
    end
  end

  def create_or_update_repo(dir)
    org = Sinatra::Application.github_organization
    repo_name = site.slug
    if site.github
      github_repository = site.github
    else
      github_repository = "#{org}/#{repo_name}"
      site.github = github_repository
      site.save
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

  def with_tmp_dir(&block)
    Dir.mktmpdir do |tmp_dir|
      Dir.chdir(tmp_dir, &block)
    end
  end

  def templates_dir
    File.expand_path(File.join('..', '..', '..', 'jekyll', 'templates'), __FILE__)
  end

  def repo_dir
    File.expand_path(File.join('..', '..', '..', 'jekyll', 'repo'), __FILE__)
  end
end
