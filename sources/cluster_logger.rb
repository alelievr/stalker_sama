require "oauth2"
require "json"

class ClusterLogger

	UID = ENV['API42_UID']
	SECRET = ENV['API42_SECRET']

	def initialize()

		@client = OAuth2::Client.new(UID, SECRET, site: "https://api.intra.42.fr")
		@token = @client.client_credentials.get_token
	end

	def update_logger(user_list)
		#TODO: Get the intra login for users

		endpoint = "/v2/locations"
	
		response = @token.get(endpoint + "?" + "filter[user_id]=" + user_list.join(','))
		#response = @token.get(endpoint)

		connected = []

		if (response.status == 200)
			response.parsed.each { |data|
				if (data['end_at'] == nil)
					connected.push(data['user']['login'])
					print(data['user']['login'] + " is connected")
				end
			}
		end
	end

end
