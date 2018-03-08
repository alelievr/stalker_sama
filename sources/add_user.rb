#!env ruby
require 'oauth2'
require_relative "slack_pinger.rb"
require_relative "user_database.rb"

db = UserDatabase.new
sb = SlackPinger.new

if ARGV[0] && ARGV[1]
	client = OAuth2::Client.new(ENV['API42_UID'], ENV['API42_SECRET'], site: "https://api.intra.42.fr")
	token = client.client_credentials.get_token
	res = token.get("/v2/users?filter[login]=#{ARGV[0]}")
	opts = {}

	exit -1 unless res.status == 200

	p "found user id:#{res.parsed[0]['id']} -> #{res.parsed[0]['login']}"
	api42_id = res.parsed[0]['id']

	res = token.get("/v2/locations?filter[user_id]=#{api42_id}")

	exit -1 unless res.status == 200

	opts[:logged] = res.parsed[0]['end_at'].nil?
	opts[:last_connected] = opts[:logged] ? res.parsed[0]['begin_at'] : res.parsed[0]['end_at']
	opts[:last_seat] = res.parsed[0]['host']

	puts "last_connected: #{opts[:last_connected]}"

	res = token.get("/v2/cursus_users?filter[user_id]=#{api42_id}&cursus_id=1")

	exit -1 unless res.status == 200

	opts[:level] = res.parsed[0]['level']

	slack_id = sb.get_user_id(ARGV[1]);

	print "slack id found: #{slack_id}"

	db.add_user(ARGV[0], api42_id, slack_id, opts)
else
	p "Give me the 42 login and slack user name"
end
