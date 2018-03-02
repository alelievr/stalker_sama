require_relative "cluster_logger.rb"
require_relative "user_database.rb"
require_relative "slack_bot.rb"

cluster = ClusterLogger.new
slack = SlackBot.new
db = UserDatabase.new

user_list = ["19857"];

while true

	connected_logins = cluster.update_logger(user_list);

	#TODO: diff with db and slack send API
	#db.get_users()

	#db.update_connected(connected_logins)

	sleep 10
end
