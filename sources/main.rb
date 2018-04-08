require_relative 'cluster_logger.rb'
require_relative 'project_logger.rb'
require_relative 'user_database.rb'
require_relative 'slack_pinger.rb'
require_relative 'slack_bot.rb'
require 'awesome_print'

cluster = ClusterLogger.new
project = ProjectLogger.new
slack = SlackPinger.new
SlackBot.new

old_connected_infos = nil

def log(c1, c2, slack_id, users)
  	puts "\nTime: #{Time.now}"
	ap c1
	puts "\n"
	ap c2
  puts "slack_id ----------------------------------------------"
  ap slack_id
  puts "users -------------------------------------------------"
  ap users
	puts "-------------------------------------------------------\n\n"
	STDOUT.flush
end

while true

  db = UserDatabase.new

  users = db.get_users
  users_api42_ids = users.map { |u| u[:api42_id] }

  begin
  	connected_infos = cluster.update_logger(users_api42_ids)
  	projects_infos = project.get_infos(users_api42_ids)
  rescue Exception => e
	puts "En error occured: #{e.message}"
	next
  end

  users.each do |user|
    #cluster.update_user(connected_infos, user, slack, db)
    project.update_user(projects_infos, user, slack, db)
  end

  cluster.update_users(connected_infos, db)

  if !old_connected_infos.nil?

#	connected_infos.map! do |c| 
#		next c unless c[:login] == 'alelievr'
#		c[:connected] = false
#		c
#  	end

	halp_me = connected_infos.map{ |c| [c, old_connected_infos.find{ |c2| c2[:login] == c[:login] }] }

	halp_me.each do |c1, c2|

		next unless c2

		slack_id = users.find{|u| u[:login42] == c1[:login]}[:slack_id]
		if (c1[:connected] && !c2[:connected])
			log(c1, c2, slack_id, users)
        	slack.send_connected_message(c1[:login], slack_id, {secs: 1, seat: c1[:seat]})
		end
		if (!c1[:connected] && c2[:connected])
			log(c1, c2, slack_id, users)
        	slack.send_disconnected_message(c1[:login], slack_id, {secs: Time.parse(c1[:end_at]) - Time.parse(c2[:begin_at]), seat: c1[:seat]})
		end
    end
  end

  old_connected_infos = connected_infos

  db.close

  sleep 10
end
