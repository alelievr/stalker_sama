require 'slack-ruby-client'
require 'awesome_print'
require_relative 'user_database.rb'

class SlackBot

	def initialize
		Slack.configure do |config|
			config.token = ENV['SLACK_API_TOKEN']
			config.logger = Logger.new(STDOUT)
			config.logger.level = Logger::WARN
			raise 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
		end

		@ud = UserDatabase.new


		@client = Slack::RealTime::Client.new

		@client.on :message do |data| onMessage(data) end

		@client.on :hello do
			  puts "Successfully connected, welcome '#{@client.self.name}' to the '#{@client.team.name}' team at https://#{@client.team.domain}.slack.com."
		end

		@client.on :close do |_data|
			  puts 'Connection closing, exiting.'
		end

		@client.on :closed do |_data|
			  puts 'Connection has been disconnected.'
		end

		@client.start!

	end

	def sendMessage(chan, text)
		@client.typing channel: chan
		@client.message channel: chan, text: text
	end

	def onMessage(data)
		#data:
		#"type" => "message",
		#"channel" => "D9JE10EBG",
		#"user" => "U9GUFLZ9N",
		#"text" => "yo",
		#"ts" => "1520183877.000114",
		#"source_team" => "T9B6RUSKT",
		#"team" => "T9B6RUSKT"

		case data.text
		when 'bot hi' then
			sendMessage(data.channel, "Hi <@#{data.user}>!")
		when /.*cluster.*/i, /.*stalker.*/i then
			case data.text
			when /.*who.*connected.*/i then
				sendMessage(data.channel, @ud.get_users().map{|u| "#{u[:login42]} @ #{u[:last_seat]}" if u[:connected]}.compact.join("\n"))
			end
		end

	end
end
