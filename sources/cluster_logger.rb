require "oauth2"
require "json"

class ClusterLogger

	UID = ENV['API42_UID']
	SECRET = ENV['API42_SECRET']

	def initialize()

		@client = OAuth2::Client.new(UID, SECRET, site: "https://api.intra.42.fr")
		@token = @client.client_credentials.get_token
	end

	def update_logger(user_list, endpoint = "/v2/locations")

		return [] unless user_list.count != 0

		response = @token.get("#{endpoint}?filter[user_id]=#{user_list.join(',')}")
		#response = @token.get(endpoint)

		return unless response.status == 200

		connected = []
		response.parsed.each { |data|

			next unless data['end_at'].nil? or data['primary'] == false

			puts data['host']

			connected.push({login: data['user']['login'], seat: data['host']})

			p "#{data['user']['login']} is connected"
		}

		return connected;
	end

end
