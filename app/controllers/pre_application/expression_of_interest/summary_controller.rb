# Controller for the expression of interest 'check your answers' page
class PreApplication::ExpressionOfInterest::SummaryController < ApplicationController
  include PreApplicationContext

  def show
    @organisation = Organisation.find(@pre_application.organisation_id)
    # 'HTTP_REFERER' is the url for the page that brought the journey here.
    @last_page = request.env['HTTP_REFERER']
  end

end
