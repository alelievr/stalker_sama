require_relative "cluster_logger.rb"
require_relative "user_database.rb"
require_relative "slack_pinger.rb"
require_relative "slack_bot.rb"
require "awesome_print"

cluster = ClusterLogger.new
slack = SlackPinger.new
db = UserDatabase.new
SlackBot.new

while true

	users = db.get_users()

	connected_infos = cluster.update_logger(users.map{|u| u[:api42_id]});

	#puts "Users:"
	#ap users
	#puts "Connected infos:"
	#ap connected_infos

	users.each{ |user|
		secs = Time.now - Time.parse(user[:last_connected])
		user_info = connected_infos.detect{|i| i[:login] == user[:login42]}
		a = user_info[:seat] if user_info
		a ||= ''
		opts = {secs: secs, seat: a}

		#puts "User info:"
		#ap user_info

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

	begin
		db.update_connected(connected_logins)
	rescue e
		puts "42 API update error: #{e}"
	end

	sleep 10
end
