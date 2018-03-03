require 'slack-ruby-client'
require 'json'

class SlackBot

	CHAN = "#clusters-test"

	def initialize
		Slack.configure do |config|
			config.token = ENV['SLACK_API_TOKEN']
			config.logger = Logger.new(STDOUT)
			config.logger.level = Logger::WARN
			raise 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
		end

		@connect_quotes = JSON.parse(File.read("./connect_quotes.json"))
		@disconnect_quotes = JSON.parse(File.read("./disconnect_quotes.json"))

		@client = Slack::Web::Client.new
	end

	def pick_random_from_hours(user_hours, quotes)
		quotes.each { |quote|
			next unless quote['hour'] >= user_hours

			return quote['messages'].sample
		}
	end

	def send_message(message)
		return if message == nil || message == ""

		puts "Sending message: #{message}"

		@client.chat_postMessage(channel: CHAN, text: message, as_user: true, link_names: 1)
	end

	def humanize secs
		[[60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map{ |count, name|
			if secs > 0
				secs, n = secs.divmod(count)
				"#{n.to_i} #{name}"
			end
		}.compact.reverse.join(' ')
	end


	def format_message(message, login42, slack_id, secs)
		infos = @client.users_info(user: slack_id);

		JSON.dump(infos)

		message.gsub! '{slack_ping}', "<@#{infos.user.name}>(#{login42})"
		message.gsub! '{login42}', "#{login42}"
		message.gsub! '{hours}', "#{(secs / 60).round(2)}"
		message.gsub! '{secs}', "#{secs}"
		message.gsub! '{readable_time}', "#{humanize(secs)}"

		return message
	end

	def send_connected_message(login42, slack_id)
		send_message(format_message(pick_random_from_hours(0, @connect_quotes), login42, slack_id, 0))
	end

	def send_disconnected_message(login42, slack_id, hours)
		send_message(format_message(pick_random_from_hours(hours, @disconnect_quotes), login42, slack_id, hours))
	end

	def get_user_id(user_login)
		infos = @client.users_info(user: "@#{user_login}")

		return infos.user.id
	end

end
