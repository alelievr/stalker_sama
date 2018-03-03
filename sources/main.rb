require_relative "cluster_logger.rb"
require_relative "user_database.rb"
require_relative "slack_bot.rb"

cluster = ClusterLogger.new
slack = SlackBot.new
db = UserDatabase.new

while true

	users = db.get_users()

	connected_logins = cluster.update_logger(users.map{|u| u[:api42_id]});

	users.each{ |user|
		if connected_logins.include? user[:login42]
			if !user[:connected]
				slack.send_connected_message(user[:login42], user[:slack_id])
			end
		else
			if user[:connected]
				slack.send_disconnected_message(user[:login42], user[:slack_id], Time.now - Time.parse(user[:last_connected]))
			end
		end
	}

	db.update_connected(connected_logins)

	sleep 10
end
