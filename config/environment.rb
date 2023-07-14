# Load the Rails application.
require_relative "application"

# Stop Rails from wrapping a 'fields_with_error' div around any input
# fields that correspond to a model error.
# See https://stackoverflow.com/a/5268112/5890174
ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  html_tag.html_safe
end

# Initialize the Rails application.
Rails.application.initialize!
