require "oauth2"
require "json"
require "awesome_print"

class ClusterLogger

	UID = ENV['API42_UID']
	SECRET = ENV['API42_SECRET']

	def initialize()

		@client = OAuth2::Client.new(UID, SECRET, site: "https://api.intra.42.fr")
		@token = @client.client_credentials.get_token
	end

	def update_logger(user_list, endpoint = "/v2/locations")

		return [] unless user_list.count != 0

		connected = []

		for i in 1..10
			time = Time.now.strftime("%G-W%V-%uT%T")
			uri = "#{endpoint}?filter[user_id]=#{user_list.join(',')}&sort=-end_at&filter[-end_at]&page=#{i}"

			initialize if (Time.now.to_i - @token.expires_at).abs < 200
			response = @token.get(uri)

			break if response.parsed.all? {|p| !p['end_at'].nil? }

			throw "Bad api status: #{response.status}" unless response.status == 200

			#ap response.parsed

			response.parsed.each { |data|

				next unless data['end_at'].nil?

				connected.push({login: data['user']['login'], seat: data['host']})

				p "#{data['user']['login']} is connected"
			}

			sleep 3

		end

		return connected;
	end

end
