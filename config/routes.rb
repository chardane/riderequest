Rails.application.routes.draw do
  root 'home#index'
  get 'oauth2/callback' => 'home#callback'
  get 'request_uber' => 'home#request_uber'
  get 'ride_status' => 'home#ride_status'
end
