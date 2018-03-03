require_relative "cluster_logger.rb"
require_relative "user_database.rb"
require_relative "slack_bot.rb"

cluster = ClusterLogger.new
slack = SlackBot.new
db = UserDatabase.new

while true

	users = db.get_users()

	connected_infos = cluster.update_logger(users.map{|u| u[:api42_id]});

	users.each{ |user|
		secs = Time.now - Time.parse(user[:last_connected])
		user_info = connected_infos.detect{|i| i[:login] == user[:login42]}
		opts = {secs: secs, seat: user_info[:seat]}
		if user_info.nil?
			if !user[:connected]
				slack.send_connected_message(user[:login42], user[:slack_id], opts)
			end
		else
			if user[:connected]
				slack.send_disconnected_message(user[:login42], user[:slack_id], opts)
			end
		end
	}

	connected_logins = connected_infos.map{ |i| i[:login] }

	db.update_connected(connected_logins)

	sleep 10
end
