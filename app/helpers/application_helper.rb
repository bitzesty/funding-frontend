module ApplicationHelper
  require_relative './nlhf_form_builder'
  require 'uri'
  include Project::CalculateTotalHelper

  # Method to take a specified URL and replace or introduce
  # a locale query string equal to the locale string argument 
  # passed into the method
  #
  # @param [string] url     A string representation of a URL
  # @param [string] locale  A string representation of a locale
  def replace_locale_in_url(url, locale)

    parsed_url = URI.parse(url)

    parsed_query_strings = Rack::Utils.parse_query(parsed_url.query)

    parsed_query_strings['locale'] = locale
    parsed_url.query = Rack::Utils.build_query(parsed_query_strings)

    parsed_url.to_s

  end

end
