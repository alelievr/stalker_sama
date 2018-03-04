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

	def pick_random_from_hours(user_secs, quotes)
		user_hours = user_secs / 60 / 60

		quotes.each { |quote|
			next unless quote['hour'] >= user_hours

			return quote['messages'].sample
		}
		throw "You're not supposed to be here"
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


	def format_message(message, login42, slack_id, opts = {})
		infos = @client.users_info(user: slack_id);

		message.gsub! '{ping}', "<@#{infos.user.name}>"
		message.gsub! '{42_login}', login42
		message.gsub! '{slack_login}', infos.user.name
		message.gsub! '{time}', humanize(opts[:secs].to_f).to_s
		message.gsub! '{seat}', opts[:seat]

		return message
	end

	def send_connected_message(login42, slack_id, opts = {})
		quote = pick_random_from_hours(opts[:secs], @connect_quotes)
		send_message(format_message(quote, login42, slack_id, opts))
	end

	def send_disconnected_message(login42, slack_id, opts = {})
		quote = pick_random_from_hours(opts[:secs], @disconnect_quotes)
		send_message(format_message(quote, login42, slack_id, opts))
	end

	def get_user_id(user_login)
		login = user_login
	
		@client.users_list(presence: true, limit: 10) do |response|
			r = response.members.detect{ |r| r.profile.real_name == user_login || r.profile.display_name == user_login || r.name == user_login }
			login = r.name if !r.nil?
			break if !r.nil?
		end
		
		puts "Using slack name #{login}"

		infos = @client.users_info(user: "@#{login}")

		return infos.user.id
	end

end
