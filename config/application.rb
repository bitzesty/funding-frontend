require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you"ve limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

HOSTNAME = ENV["HOSTNAME"] # Rails 7 Update recommend removing
# Rails 7 Update recommend removing, but I think we need this
module FundingFrontendRuby
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.assets.paths << Rails.root.join("node_modules")
    config.i18n.default_locale = :"en-GB"
    config.i18n.fallbacks = true
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid

      hacker = Module.new do
        def options_for_migration
          ar = Rails.application.config.generators.active_record
          return super unless %i[belongs_to references].include?(type) && \
                              ar[:primary_key_type] == :uuid
    
          { type: :uuid }.merge(super)
        end
      end
      require "rails/generators/generated_attribute"
      Rails::Generators::GeneratedAttribute.prepend hacker
    end

    # Autoload models from subdirectories in the models/application/common directory
    # For each additional subdirectory, we will need to appened to config.eager_load_paths
    # Autoloader deprecated in Rails 7

    config.eager_load_paths += Dir[Rails.root.join("app", "models", "application", "common")]
    config.eager_load_paths += Dir[Rails.root.join("app", "models", "pre_application")]
    config.eager_load_paths += Dir[Rails.root.join("app", "models", "progress_and_spend")]
    config.eager_load_paths += Dir[Rails.root.join("app", "helpers")]
    config.eager_load_paths += Dir[Rails.root.join("lib", "apis", "salesforce")]
    config.eager_load_paths += Dir[Rails.root.join("lib", "apis", "salesforce", "salesforce_experience_application")]
    config.eager_load_paths += Dir[Rails.root.join("lib", "apis", "salesforce", "agreements")]
    config.eager_load_paths += Dir[Rails.root.join("lib", "apis", "salesforce", "progress_update")]
    config.eager_load_paths += Dir[Rails.root.join("lib", "apis", "salesforce", "payment_request")]
    config.eager_load_paths += Dir[Rails.root.join("lib", "apis", "salesforce", "organisation")]
    config.eager_load_paths += Dir[Rails.root.join("lib", "apis", "salesforce", "import")]

    # Load locale dictionaries from subdirectories in the config/locales directory. We 
    # have to apply this setting, as the default locale loading mechanism in Rails does not 
    # load locale dictionaries in nested directories
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]

    # Specify available locales for the application
    config.i18n.available_locales = [:en, :"en-GB", :cy]
    
    # config.active_record.schema_format = :sql

    # Use new connection handling API. For most applications this won't have any
    # effect. For applications using multiple databases, this new API provides
    # support for granular connection swapping.
    Rails.application.config.active_record.legacy_connection_handling = false

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
