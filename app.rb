require 'sinatra'
require 'tilt'
require 'tilt/erb'
require 'omniauth-twitter'
require 'sequel'
require 'open-uri'
require 'json'
require 'resque'
require 'csv'
require 'twitter'
require 'octokit'
require 'rack/flash'

require 'dotenv'
Dotenv.load

# Get a list of countries in EveryPolitician
if settings.environment == :production
  $countries_json = open('http://data.everypolitician.org/countries.json').read
else
  $countries_json = open('data/countries.json').read
end

def countries
  countries_list = JSON.parse($countries_json)
  countries = {}
  countries_list.each do |country|
    countries[country['url']] = {
      name: country['name'],
      url: country['url'],
      latest_term_csv: country['latest_term_csv']
    }
  end
  countries
end

DB = Sequel.connect(ENV['DATABASE_URL'])

# Resque Jobs

def get_csv_for_country(country)
  latest_term_csv = country[:latest_term_csv]
  term_csv = open('http://data.everypolitician.org' + latest_term_csv).read
  CSV.parse(term_csv, headers: true)
end

def parse_areas_from_csv(csv)
  areas = csv.map { |r| r['area'] }.compact.uniq
  areas = areas.map { |a| {name: a} }
  csv.each do |row|
    area = areas.find { |a| a[:name] == row['area'] }
    area[:politicians] ||= []
    area[:politicians] << {
      name: row['name'],
      twitter: row['twitter']
    }
  end
  areas
end

def create_lists_for_areas(areas, client)
  all_lists = client.lists
  areas.map do |area|
    # Twitter list names must be 25 chars or less
    name = area[:name]
    if name.length > 25
      name = name[0...25]
    end

    list = all_lists.find { |list| list.name == name }

    if !list
      list = client.create_list(name)
    end

    area[:list_id] = list.id
    area[:list_slug] = list.slug

    list_members = area[:politicians].map { |p| p[:twitter] }.compact
    client.add_list_members(list, list_members)

    area
  end
end

class JekyllSiteGenerator
  def initialize(data)
    @data = data
  end

  def generate
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        create_or_update_repo(dir)

        templates_dir = File.expand_path(File.join('..', 'jekyll', 'templates'), __FILE__)
        template = Tilt.new(File.join(templates_dir, '_config.yml.erb'))
        config_yml = template.render(
          self,
          country_name: @data[:country_name],
          list_owner_screen_name: @data[:list_owner_screen_name],
          base_url: @data[:base_url]
        )
        File.open(File.join(dir, '_config.yml'), 'w') do |f|
          f.puts(config_yml)
        end
        template = Tilt.new(File.join(templates_dir, 'area.html.erb'))
        @data[:areas].each do |area|
          File.open(File.join(dir, '_areas', "#{area[:list_slug]}.html"), 'w') do |f|
            f.puts(template.render(self, area))
          end
        end

        `git add .`
        author = "#{gh_client.login} <#{gh_client.emails.first[:email]}>"
        message = "Automated commit for #{@data[:country_name]}"
        `git commit --author="#{author}" --message="#{message}"`
        `git push --quiet origin gh-pages`
      end
    end
  end

  def create_or_update_repo(dir)
    repo_name = @data[:base_url].gsub('/', '')
    begin
      repo = gh_client.repository("seepoliticianstweet/#{repo_name}")
      `git clone --quiet #{clone_url(repo)} .`
    rescue Octokit::NotFound
      # Repository doesn't exist yet
      repo = gh_client.create_repository(
        repo_name,
        organization: 'seepoliticianstweet',
        homepage: "https://seepoliticianstweet.github.io/#{repo_name}"
      )
      `git init`
      `git symbolic-ref HEAD refs/heads/gh-pages`
      `git remote add origin #{clone_url(repo)}`
    end

    # Update files in repo
    FileUtils.cp_r(File.expand_path(File.join('..', 'jekyll', 'repo'), __FILE__) + '/.', dir)
  end

  def clone_url(repo)
    repo_clone_url = URI.parse(repo.clone_url)
    repo_clone_url.user = gh_client.login
    repo_clone_url.password = gh_client.access_token
    repo_clone_url
  end

  def gh_client
    @gh_client ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end
end

# Resque job to create Twitter lists from country data
class FetchDataJob
  @queue = :default

  def self.perform(country_id)
    country = DB[:countries]
      .join(:users, :id => :user_id)
      .first(Sequel.qualify(:countries, :id) => country_id)
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = country[:token]
      config.access_token_secret = country[:secret]
    end

    csv = get_csv_for_country(country)
    areas = parse_areas_from_csv(csv)
    areas = create_lists_for_areas(areas, client)

    # Create a list with all members in
    all_list = client.lists.find { |list| list.name == 'All' }
    if !all_list
      all_list = client.create_list('All')
    end
    all_twitter_handles = csv.map do|row|
      row['twitter'] if row['twitter']
    end.compact
    client.add_list_members(all_list, all_twitter_handles)

    # Generate the static site
    data = {
      base_url: country[:url],
      country_name: country[:name],
      list_owner_screen_name: client.user.screen_name,
      areas: areas
    }

    JekyllSiteGenerator.new(data).generate
  end
end

# Sinatra Application

configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET')
  set :countries, countries

  Resque.redis = ENV['REDISTOGO_URL']
end

use OmniAuth::Builder do
  provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
end

use Rack::Flash

helpers do
  def current_user
    @current_user ||= DB[:users].first(id: session[:user_id])
  end
end

# Step 1 - Select a country
get '/' do
  if current_user
    @countries = DB[:countries].where(user_id: session[:user_id])
  end
  erb :index
end

# Step 2 Sign in with Twitter
get '/auth/:name/callback' do
  auth = request.env['omniauth.auth']
  p auth
  users = DB[:users]
  user = users.first(twitter_uid: auth[:uid])
  if user
    session[:user_id] = user[:id]
  else
    session[:user_id] = users.insert(
      twitter_uid: auth[:uid],
      token: auth[:credentials][:token],
      secret: auth[:credentials][:secret]
    )
  end
  flash[:notice] = "You have successfully logged in with Twitter"
  redirect to('/')
end

get '/logout' do
  session.clear
  flash[:notice] = "You have been logged out"
  redirect to('/')
end

before '/countries*' do
  redirect to('/auth/twitter') if current_user.nil?
end

get '/countries/new' do
  erb :country_new
end

post '/countries' do
  country = countries[params[:country]]
  country_id = DB[:countries].insert(
    name: country[:name],
    url: country[:url],
    latest_term_csv: country[:latest_term_csv],
    user_id: current_user[:id]
  )
  Resque.enqueue(FetchDataJob, country_id)
  flash[:notice] = "See Politicians Tweet app is being build for this country"
  redirect to("/countries/#{country_id}")
end

get '/countries/:id' do
  @country = DB[:countries].first(id: params[:id])
  erb :country
end

post '/countries/:id/rebuild' do
  Resque.enqueue(FetchDataJob, params[:id])
  flash[:notice] = "Your rebuild request has been queued"
  redirect to('/')
end
