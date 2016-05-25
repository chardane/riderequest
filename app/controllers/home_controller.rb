class HomeController < ApplicationController
  def index
    @sign_in_link = UberClient.new.authorize_url
  end

  def callback
    # exchange code for access token
    auth_details = UberClient.new.retrieve_access_token(params[:code], request.base_url)
    # persist the token so we can use it later
    session[:access_token] = auth_details.token
  end

  def request_uber
    # convert location entered into lat and long
    pickup = find_location(params[:pickup_location])
    dropoff = find_location(params[:dropoff_location])

    # get a list of estimates
    @time_estimates = UberClient.new.get_estimates_by_pickup_location(
      session[:access_token],
      pickup['geometry']['location']
    )

    # save pickup and dropoff location to session
    session[:pickup_location] = pickup['geometry']['location']
    session[:dropoff_location] = dropoff['geometry']['location']
    session[:pickup_formatted_location] = pickup['formatted_address']
    session[:dropoff_formatted_location] = dropoff['formatted_address']

    # make these available to the view
    @pickup_formatted_location = pickup['formatted_address']
    @dropoff_formatted_location = dropoff['formatted_address']
  end

  def ride_status
    # request a ride
    response = UberClient.new.request_ride(
      access_token: session[:access_token],
      pickup: session[:pickup_location],
      dropoff: session[:dropoff_location],
      product: params[:product]
    )

    session[:request_id] = response['request_id']

    # make these available to the view
    @pickup_formatted_location = session[:pickup_formatted_location]
    @dropoff_formatted_location = session[:dropoff_formatted_location]
    @token = session[:access_token]
    @request_id = response['request_id']
    @base_url = UberClient::BASE_URL
  end

  private

  def find_location(location)
    Geocoder.search(location).first.data
  end
end
