require 'json'
require 'awesome_print'
require_relative 'api42'

class ClusterLogger < Api42
  def update_logger(user_list, endpoint = '/v2/locations')
    return [] unless user_list.count != 0

    connected = []

    [1..10].map do |page|
      response = send_uri("#{endpoint}?filter[user_id]=#{user_list.join(',')}&sort=-end_at&filter[-end_at]&page=#{page}")

      break if response.all? { |p| !p['end_at'].nil? }

      #ap response

      response.each do |data|
        next unless data['end_at'].nil?

        connected.push({ login: data['user']['login'], seat: data['host'] })
      end

      sleep 3
    end

    connected
  end

  def update_user(connected_infos, user, slack, db)
    secs = Time.now - Time.parse(user[:last_connected])
    user_info = connected_infos.detect { |i| i[:login] == user[:login42] }
    a = user_info[:seat] if user_info
    a ||= ''
    opts = { secs: secs, seat: a }

    if user_info.nil?
      if user[:connected]
        slack.send_disconnected_message(user[:login42], user[:slack_id], opts)
        db.update_user(user[:login42], :last_connected, Time.now)
      end
    else
      unless user[:connected]
        slack.send_connected_message(user[:login42], user[:slack_id], opts)
        db.update_user(user[:login42], :last_connected, Time.now)
      end
	  db.update_user(user[:login42], :last_seat, user_info[:seat])
    end
  end

  def update_users(connected_infos, db)
    db.update_connected(connected_infos.map { |i| i[:login] })
  rescue e
    puts "42 API update error: #{e}"
  end
end
