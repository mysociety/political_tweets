require 'fileutils'

class JekyllSiteGeneratorJob
  include Sidekiq::Worker

  attr_reader :site

  def perform(site_id, local_jekyll_path = 'generated_jekyll_sites/')
    @site = Site[site_id]
    if Sinatra::Application.use_github?
      site.with_git_repo { |repo| update_templates(repo) }
    else
      FileUtils.mkdir_p(local_jekyll_path)
      update_templates(File.join(local_jekyll_path, site.slug))
    end
  end

  # Update files in repo
  def update_templates(dir)
    FileUtils.cp_r(repo_dir + '/.', dir)

    template = Tilt.new(File.join(templates_dir, '_config.yml.erb'))
    config_yml = template.render(self, site: site)
    File.write(File.join(dir, '_config.yml'), config_yml)

    FileUtils.rm_rf(File.join(dir, '_areas'))
    FileUtils.mkdir_p(File.join(dir, '_areas'))

    template = Tilt.new(File.join(templates_dir, 'area.html.erb'))
    site.areas.each do |area|
      politicians = site.grouped_areas[area.name]
      result = template.render(self, area: area, politicians: politicians)
      area_file = File.join(dir, '_areas', "#{area.slug}.html")
      File.write(area_file, result)
    end
  end

  def templates_dir
    File.expand_path(File.join('../../../jekyll/templates'), __FILE__)
  end

  def repo_dir
    File.expand_path(File.join('../../../jekyll/repo'), __FILE__)
  end
end
