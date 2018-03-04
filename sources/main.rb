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
		a = user_info[:seat] if user_info
		a ||= ''
		opts = {secs: secs, seat: a}
		if user_info.nil?
			if user[:connected]
				slack.send_disconnected_message(user[:login42], user[:slack_id], opts)
				db.update_time(user[:login42])
			end
		else
			if !user[:connected]
				slack.send_connected_message(user[:login42], user[:slack_id], opts)
				db.update_time(user[:login42])
			end
		end
	}

	connected_logins = connected_infos.map{ |i| i[:login] }

	db.update_connected(connected_logins)

	sleep 10
end
