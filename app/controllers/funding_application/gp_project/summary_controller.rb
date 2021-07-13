class FundingApplication::GpProject::SummaryController < ApplicationController
  include FundingApplicationContext
  layout "summary"
  
  def show
    # 'HTTP_REFERER' is the url for the page that brought the journey here.
    @last_page = request.env['HTTP_REFERER']
  end

end
