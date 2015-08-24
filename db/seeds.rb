require_relative '../app'

$stderr.puts 'Loading database seeds'

database = Sinatra::Application.database

user = database[:users].first

if user.nil?
  user_id = database[:users].insert(
    id: 1,
    twitter_uid: '3254010850',
    token: 'token',
    secret: 'secret'
  )
  user = database[:users].first(id: user_id)
end

sites = [
  { name: 'Wales', url: '/wales', github: 'seepoliticianstweet/wales', latest_term_csv: '/wales/term_table/4.csv', user_id: user[:id] },
  { name: 'France', url: '/france', latest_term_csv: '/france/term_table/7.csv', user_id: user[:id] },
  { name: 'Spain', url: '/spain', latest_term_csv: '/spain/term_table/7.csv', user_id: user[:id] }
]

sites.each { |site| database[:sites].insert(site) }
