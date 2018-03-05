require_relative 'cluster_logger.rb'
require_relative 'project_logger.rb'
require_relative 'user_database.rb'
require_relative 'slack_pinger.rb'
require_relative 'slack_bot.rb'
require 'awesome_print'

cluster = ClusterLogger.new
project = ProjectLogger.new
slack = SlackPinger.new
db = UserDatabase.new
SlackBot.new

# def project_update(projects_infos, user)
#   project_info = projects_infos.detect { |i| i[:login] == user[:login42] }
# end

while true

  users = db.get_users
  users_api42_ids = users.map { |u| u[:api42_id] }

  connected_infos = cluster.update_logger(users_api42_ids)
  projects_infos = project.get_infos(users_api42_ids)

  #puts "Users:"
  #ap users
  #puts "Connected infos:"
  #ap connected_infos

  users.each do |user|
    cluster.update_user(connected_infos, user, slack, db)
    project.update_user(projects_infos, user, slack, db)

    #puts "User info:"
    #ap user_info
  end

  cluster.update_users(connected_infos, db)

  sleep 10
end
