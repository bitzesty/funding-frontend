# Controller for the project enquiry 'check answers' page
class PreApplication::ProjectEnquiry::SummaryController < ApplicationController
  include PreApplicationContext
  layout "summary"

  def show
    @organisation = Organisation.find(@pre_application.organisation_id)
    # 'HTTP_REFERER' is the url for the page that brought the journey here.
    @last_page = request.env['HTTP_REFERER']
  end

end
