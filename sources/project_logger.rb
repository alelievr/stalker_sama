require 'json'
require 'awesome_print'
require_relative 'api42'

class ProjectLogger < Api42
  def get_infos(user_list, endpoint = '/v2/cursus_users')
    return [] unless user_list.count.positive?

    levels = []
    [1..10].map do |page|
      response = send_uri("#{endpoint}?filter[user_id]=#{user_list.join(',')}&cursus_id=1&page=#{page}")

      response.map { |data| levels.push({ login: data['user']['login'], level: data['level'] }) }

      sleep 3
    end
    levels
  end

  def update_user(project_infos, user, slack, db)
    user_info = project_infos.detect { |i| i[:login] == user[:login42] }
    opts = { level: user_info[:level], xp: (user_info[:level] - user[:level]) }
    
    return unless opts[:xp].positive?

    slack.send_project_message(user[:login42], user[:slack_id], opts)
    db.update_user(user[:login42], :level, user_info[:level])
  end
end
