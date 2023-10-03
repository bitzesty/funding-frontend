# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Eager loading loads your whole application. When running a single test locally,
  # this probably isn't necessary. It's a good idea to do in a continuous integration
  # system, or in some way before deploying your code.
  config.eager_load = false
  config.eager_load = ENV["CI"].present? # But check eagerload there.

  # Turn false under Spring and add config.action_view.cache_template_loading = true.
  config.cache_classes = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  config.action_mailer.default_url_options = { host: 'test.example.com' }

  config.action_mailer.default_options = { from: 'no-reply@example.com' }


  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  config.active_storage.service = :test
  config.x.salesforce.host = "test.salesforce.com"
  config.x.salesforce.username = "test"
  config.x.salesforce.password = "test"
  config.x.salesforce.security_token = "test"
  config.x.salesforce.client_id = "test"
  config.x.salesforce.client_secret = "test"

  config.x.payment_encryption_key = "test"
  config.x.payment_encryption_salt = "test"

  config.x.support_email_address = "test@test.com"
  config.x.reply_email_guid = "reply@test.com"
  config.x.no_reply_email_address = "no_reply@test.com"
  config.x.ideal_postcodes.api_key = "test"
  config.x.consumer.username = 'test'
  config.x.consumer.password = 'test'
end
