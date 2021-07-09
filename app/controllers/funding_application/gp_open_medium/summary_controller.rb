# Controller for a page that asks shows the summary
class FundingApplication::GpOpenMedium::SummaryController < ApplicationController
  include FundingApplicationContext

  def show
    # 'HTTP_REFERER' is the url for the page that brought the journey here.
    @last_page = request.env['HTTP_REFERER']
  end

end
