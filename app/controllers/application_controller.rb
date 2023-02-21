# Top-level ApplicationController class, which inherits directly
# from ActionController::Base and is then inherited by all
# other controllers
class ApplicationController < ActionController::Base
  default_form_builder(NlhfFormBuilder)
  include LocaleHelper
  before_action :check_ffe_enabled!
  around_action :switch_locale

  # Appends the locale URL parameter to all URLs, where the
  # argument is the current I18n.locale value
  def default_url_options
    { locale: I18n.locale }
  end

  def check_ffe_enabled!
    if Flipper.enabled?(:disable_ffe)
       redirect_to :service_unavailable
    end
  end

end
