require 'slack-ruby-bot'

class SlackBot < SlackRubyBot::Bot

	CHAN = "general"

	def send_message(message)
		@client.say(text: message, channel: CHAN)
	end

end
