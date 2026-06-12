Rails.application.configure do
  config.fly_api_token = ENV["FLY_API_TOKEN"]
  config.rating_calculation_app_name = ENV["RATING_CALCULATION_APP_NAME"]
end
