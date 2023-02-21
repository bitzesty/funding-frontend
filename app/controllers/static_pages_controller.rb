# Controller responsible for rendering static pages
class StaticPagesController < ApplicationController
  skip_before_action :check_ffe_enabled!

  # Method responsible for rendering the 'Accessibility statement' page
  def show_accessibility_statement
    render('static_pages/accessibility_statement/show')
  end

  def show_service_unavailable_page
    render('static_pages/service_unavailable/show')
  end

end
