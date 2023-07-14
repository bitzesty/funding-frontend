# Removing require a breaking change for Rails 7
require 'silencer/rails/logger'

Rails.application.configure do

  config.middleware.insert_before(
      Rails::Rack::Logger, 
      Silencer::Logger, 
      config.log_tags,
      silence: ["/health"]
  )
end