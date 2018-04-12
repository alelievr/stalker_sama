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
      on_direct_message(data) if data.channel[0] == 'D'
      on_channel_message(data) if data.channel[0] == 'C'
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

  def send_message(chan, text)
    @client.typing channel: chan
    @client.message channel: chan, text: text
  end

  def on_channel_message(data)
    #data:
    #"type" => "message",
    #"channel" => "D9JE10EBG",
    #"user" => "U9GUFLZ9N",
    #"text" => "yo",
    #"ts" => "1520183877.000114",
    #"source_team" => "T9B6RUSKT",
    #"team" => "T9B6RUSKT"

    return unless data.text =~ /.*cluster/i || data.text =~ /.*stalker.*/i

    puts data.text
    on_direct_message(data)
  end

  def on_direct_message(data)
    return unless data.subtype.nil?

    ap data
    case data.text
    when /(\W+hi|^hi|\W+hey|^hey|^hello|\W+hello)\W+/i
      send_message(data.channel, "Hi <@#{data.user}> !")
    when /where.*you/i
      send_message(data.channel, 'In your back !')
    when /is.*weak.*\?/
      send_message(data.channel, 'Yes !')
    when /who.*connected/i
      react(data, :eyes)
      send_message(data.channel, @ud.get_users.map { |u| "#{u[:login42]} @ #{u[:last_seat]} ()" if u[:connected] }.compact.join("\n"))
    else
      q = data.text.sub(/.*(stalker[s]?|cluster[s]?)\s*[\?\.,!:]*/i, '')
      react(data, :thinking_face)
      send_message(data.channel, ask_google(q))
    end
  end

  def ask_google(query)
    return 'Nope sorry' if query.strip.empty?
    puts "query: #{query}"
    results = JSON.parse HTTP.get('https://www.googleapis.com/customsearch/v1', params: {
                                                                                          q: query,
                                                                                          key: ENV['GOOGLE_API_KEY'],
                                                                                          cx: ENV['GOOGLE_CSE_ID']
                                                                                        })
    result = results['items'].first if results['items']

    return 'Daily search limit exedeed !' if results['error'] && results['error']['code'] == 403

    result ? "#{result['title']}\n#{result['link']}" : 'Wait what ?'
  end

  def react(data, name)
    @client.web_client.reactions_add(name: name, channel: data.channel, timestamp: data.ts, as_user: true)
  end
end
