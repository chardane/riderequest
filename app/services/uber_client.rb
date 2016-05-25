class UberClient
  BASE_URL = ENV['UBER_BASE_URL']
  UBER_CLIENT_ID = ENV['UBER_CLIENT_ID']
  UBER_CLIENT_SECRET = ENV['UBER_CLIENT_SECRET']

  attr_reader :token

  def initialize
    @client = oauth2_client
  end

  def authorize_url
    @client.auth_code.authorize_url(scope: 'request')
  end

  def retrieve_access_token(auth_code, redirect_base_url)
    @client.auth_code.get_token(auth_code, :redirect_uri => "#{redirect_base_url}/oauth2/callback")
  end

  def get_estimates_by_pickup_location(access_token, pickup_location)
    response = uber_http_client.get do |req|
      req.url '/v1/estimates/time'
      req.headers['Authorization'] = "Bearer #{access_token}"
      req.params['start_latitude'] = pickup_location['lat']
      req.params['start_longitude'] = pickup_location['lng']
    end

    JSON.parse(response.body)['times']
  end

  def request_ride(access_token:, pickup:, dropoff:, product:)
    response = uber_http_client.post do |req|
      req.url '/v1/requests'
      req.headers['Authorization'] = "Bearer #{access_token}"
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        start_latitude: pickup['lat'],
        start_longitude: pickup['lng'],
        end_latitude: dropoff['lat'],
        end_longitude: dropoff['lng'],
        product_id: product
      }.to_json
    end

    JSON.parse(response.body)
  end

  private

  def oauth2_client
    @client ||= OAuth2::Client.new(
      UBER_CLIENT_ID,
      UBER_CLIENT_SECRET,
      site: 'https://login.uber.com',
      authorize_url: '/oauth/v2/authorize',
      token_url: '/oauth/v2/token'
    )
  end

  def uber_http_client
    Faraday.new(:url => BASE_URL) do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end
  end
end
