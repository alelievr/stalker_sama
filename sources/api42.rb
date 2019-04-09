require 'oauth2'

class Api42
  UID = ENV['API42_UID']
  SECRET = ENV['API42_SECRET']

  def initialize
    @client = OAuth2::Client.new(UID, SECRET, site: 'https://api.intra.42.fr')
    @token = @client.client_credentials.get_token
  end

  protected

  def send_uri(uri)
    sleep(3)
    initialize if (Time.now.to_i - @token.expires_at).abs < 200
    response = @token.get(uri)

    throw "Bad api status: #{response.status}" unless response.status == 200

    response.parsed
  end
end
