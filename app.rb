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
  areas.map do |area|
    # Twitter list names must be 25 chars or less
    name = area[:name]
    if name.length > 25
      name = name[0...25]
    end

    list = client.create_list(name)
    area[:list_id] = list.id
    area[:list_slug] = list.slug

    list_members = area[:politicians].map { |p| p[:twitter] }.compact
    client.add_list_members(list, list_members)

    area
  end
end

class JekyllSiteGenerator
  def initialize(data, output_path)
    @data = data
    @output_path = output_path
  end

  def generate
    Dir.mktmpdir do |dir|
      FileUtils.cp_r('jekyll/repo', dir)
      template = Tilt.new('jekyll/templates/_config.yml.erb')
      config_yml = template.render(
        self,
        country_name: @data[:country_name],
        list_owner_screen_name: @data[:list_owner_screen_name]
      )
      File.open("#{dir}/repo/_config.yml", 'w') do |f|
        f.puts(config_yml)
      end
      template = Tilt.new('jekyll/templates/area.html.erb')
      @data[:areas].each do |area|
        File.open("#{dir}/repo/_areas/#{area[:list_slug]}.html", 'w') do |f|
          f.puts(template.render(self, area))
        end
      end
      FileUtils.cp_r("#{dir}/repo", @output_path)
    end
  end
end

# Resque job to create Twitter lists from country data
class FetchDataJob
  @queue = :default

  def self.perform(token_id)
    token = DB[:tokens].first(id: token_id)
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_KEY']
      config.consumer_secret     = ENV['TWITTER_SECRET']
      config.access_token        = token[:token]
      config.access_token_secret = token[:secret]
    end

    country = countries[token[:country]]
    csv = get_csv_for_country(country)
    areas = parse_areas_from_csv(csv)
    areas = create_lists_for_areas(areas, client)

    # Create a list with all members in
    all_list = client.create_list('All')
    all_twitter_handles = csv.map do|row|
      row['twitter'] if row['twitter']
    end.compact
    client.add_list_members(all_list, all_twitter_handles)

    # Generate the static site
    data = {
      country_name: countries[token[:country]][:name],
      list_owner_screen_name: client.user.screen_name,
      areas: areas
    }
    output_path = "#{ENV['HOME']}/Desktop/generated-jekyll-site"

    JekyllSiteGenerator.new(data, output_path).generate
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
  provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
end

# Step 1 - Select a country
get '/' do
  erb :index
end

# Step 1b - Save country to session and redirect to Twitter OAuth
post '/choose-country' do
  session[:country] = params[:country]
  redirect to('/auth/twitter')
end

# Step 2 Sign in with Twitter
get '/auth/:name/callback' do
  auth = request.env['omniauth.auth']
  tokens = DB[:tokens]
  token_id = tokens.insert(
    uid: auth[:uid],
    token: auth[:credentials][:token],
    secret: auth[:credentials][:secret],
    country: session[:country]
  )
  session[:token_id] = token_id

  Resque.enqueue(FetchDataJob, token_id)

  redirect to('/success')
end

get '/success' do
  tokens = DB[:tokens]
  @token = tokens.where(id: session[:token_id]).first
  erb :success
end

get '/logout' do
  session.clear
  redirect to('/')
end
