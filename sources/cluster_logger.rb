require 'json'
require 'time'
require 'awesome_print'
require_relative 'api42'

def log(c1, c2, opts)
  puts "\nTime: #{Time.now}"
  ap c1
  puts "\n"
  ap c2 if c2
  puts 'opts --------------------------------------------------'
  ap opts
  puts "-------------------------------------------------------\n\n"
  STDOUT.flush
end

class ClusterLogger < Api42
  def update_logger(user_list, endpoint = '/v2/locations')
    return [] unless user_list.count != 0

    connected = []

    [1..10].map do |page|
      begin
        response = send_uri("#{endpoint}?filter[user_id]=#{user_list.join(',')}&sort=-end_at&filter[-end_at]&page=#{page}")
        response.each do |data|
          connected.push(login: data['user']['login'], seat: data['host'], connected: data['end_at'].nil?, begin_at: data['begin_at'], end_at: data['end_at'])
        end
      rescue Exception => e
        puts "An error occured in 42 API: #{e}"
        return []
      end
      sleep 3
    end

    connected.uniq { |c| c[:login] }
  end

  def update_user(connected_infos, user, slack, db)
    secs = Time.now - Time.parse(user[:last_connected])
    user_info = connected_infos.detect { |i| i[:login] == user[:login42] }

    return unless user_info

    opts = { secs: secs, seat: user_info[:seat] }

    # just log in
    if user_info[:connected] && !user[:connected]
      log(user, user_info, opts)
      slack.send_connected_message(user[:login42], user[:slack_id], opts)
      db.update_user(user[:login42], :last_seat, user_info[:seat])
      db.update_user(user[:login42], :connected, true)
      return
    end

    return unless !user_info[:connected] && user[:connected]

    # just log out
    log(user, user_info, opts)

    slack.send_disconnected_message(user[:login42], user[:slack_id], opts)
    db.update_user(user[:login42], :last_connected, Time.parse(user_info[:end_at]).to_s)
    db.update_user(user[:login42], :connected, false)
  end

  def update_users(connected_infos, db)
    db.update_connected(connected_infos.map { |i| i[:login] })
  rescue e
    puts "42 API update error: #{e}"
  end
end
