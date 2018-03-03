require 'oauth2'
require_relative "slack_bot.rb"
require_relative "user_database.rb"

db = UserDatabase.new
sb = SlackBot.new

if ARGV[0] && ARGV[1]
	client = OAuth2::Client.new(ENV['API42_UID'], ENV['API42_SECRET'], site: "https://api.intra.42.fr")
	token = client.client_credentials.get_token
	res = token.get("/v2/users?filter[login]=#{ARGV[0]}")

	exit -1 unless res.status == 200

	p "found user id:#{res.parsed[0]['id']} -> #{res.parsed[0]['login']}"
	api42_id = res.parsed[0]['id']

	slack_id = sb.get_user_id(ARGV[1]);

	print "slack id found: #{slack_id}"

	db.add_user(ARGV[0], api42_id, slack_id)
else
	p "Give me the 42 login and slack user name"
end
