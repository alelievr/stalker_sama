require 'slack-ruby-client'
require 'awesome_print'
require 'json'
require 'http'
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

		@client.on :message do |data|
			onDirectMessage(data) if data.channel[0] == 'D'
			onChannelMessage(data) if data.channel[0] == 'C'
		end

		@client.on :hello do
			  puts "Successfully connected, welcome '#{@client.self.name}' to the '#{@client.team.name}' team at https://#{@client.team.domain}.slack.com."
		end

		@client.on :close do |_data|
			  puts 'Connection closing, exiting.'
		end

		@client.on :closed do |_data|
			  puts 'Connection has been disconnected.'
		end

		Thread.new { @client.start! }

	end

	def sendMessage(chan, text)
		@client.typing channel: chan
		@client.message channel: chan, text: text
	end

	def onChannelMessage(data)
		#data:
		#"type" => "message",
		#"channel" => "D9JE10EBG",
		#"user" => "U9GUFLZ9N",
		#"text" => "yo",
		#"ts" => "1520183877.000114",
		#"source_team" => "T9B6RUSKT",
		#"team" => "T9B6RUSKT"

		if data.text =~ /.*cluster/i || data.text =~ /.*stalker.*/i
			puts data.text
			onDirectMessage(data) 
		end
	end

	def onDirectMessage(data)
		return unless data.subtype.nil?

		ap data
		case data.text
		when /hi/i, /hey/i
			sendMessage(data.channel, "Hi <@#{data.user}> !")
		when /where.*you/i
			sendMessage(data.channel, "In your back !")
		when /who.*connected/i then
			sendMessage(data.channel, @ud.get_users().map{ |u| "#{u[:login42]} @ #{u[:last_seat]}" if u[:connected] }.compact.join("\n"))
		else
			q = data.text.sub(/.*(stalker[s]?|cluster[s]?)\s*[\?\.,!:]/i, '')
			sendMessage(data.channel, askGoogle(q))
		end

	end

	def askGoogle(query)
		return "Nope sorry" if query.strip.empty?
		puts "query: #{query}"
		results = JSON.parse HTTP.get('https://www.googleapis.com/customsearch/v1', params: {
            q: query,
            key: ENV['GOOGLE_API_KEY'],
            cx: ENV['GOOGLE_CSE_ID']
        })
        result = results['items'].first if results['items']
        if result
          	message = result['title'] + "\n" + result['link']
        else
          	message = "Wait what ?"
		end

		return message
	end

end
